#TODO: Better tag matching
# Right now it tries to match all the tags

class Note < Command
   include DB
   include RateLimit

   def initialize
      super('NOTE',
            'NOTE TAGS; ADD <tags> ! <note>; NOTE SEARCH <tags>',
            'See the currently used tags, add a note, or search through notes.' + 
            ' Tags should be whitespace seperated')
   end

   @@instance = Note.new()

   def getTags()
      res = db.query("SELECT DISTINCT(tag) FROM #{NOTE_TAGS_TABLE} ORDER BY tag")
      tags = Array.new()
      if (res)
         res.each{|row|
            tags << row[0]
         }
      end

      return tags
   end

   def insertNote(note, tags)
      res = db.query("INSERT INTO #{NOTES_TABLE} (id, note) VALUES (NULL, '#{escape(note)}')")
      id = db.insert_id()

      insert = "INSERT IGNORE INTO #{NOTE_TAGS_TABLE} (note_id, tag) VALUES "
      tags.each{|tag|
         insert += "(#{id}, '#{escape(tag)}'), "
      }
      insert.sub!(/, $/, '')

      db.query(insert)

      return true
   end

   def getMatchingNotes(tags)
      tagStr = ''
      tags.each{|tag|
         tagStr += "'#{escape(tag)}', "
      }
      tagStr.sub!(/, $/, '')

      res = db.query("SELECT n.note, tags.tags" +
                     " FROM" +
                     " #{NOTES_TABLE} n JOIN (" +
                     "   SELECT note_id, COUNT(*) as tag_count" +
                     "   FROM #{NOTE_TAGS_TABLE}" +  
                     "   WHERE tag IN (#{tagStr})" + 
                     "   GROUP BY note_id" +  
                     " ) counts ON n.id = counts.note_id" +
                     " JOIN (" +
                     "   SELECT note_id, GROUP_CONCAT(tag ORDER BY tag SEPARATOR ', ') as tags" +
                     "   FROM #{NOTE_TAGS_TABLE}" + 
                     "   GROUP BY note_id" +
                     " ) tags ON tags.note_id = n.id" +
                     " ORDER BY counts.tag_count DESC")
      notes = Array.new()

      if (res)
         res.each{|row|
            notes << {:note => row[0], :tags => row[1]}
         }
      end

      return notes
   end

   def onCommand(responseInfo, args, onConsole)
      args.strip!

      if (match = args.match(/^TAGS$/i))
         tagStr = getTags().join(', ').sub(/, $/, '')
         if (tagStr.length() == 0)
           responseInfo.respond('There are currently no tags.')
         else
           responseInfo.respond("Current tags: #{tagStr}")
         end
      elsif (match = args.match(/^SEARCH\s+(.*)$/i))
         tags = match[1].split(/\s+/)
         if (tags.size() == 0)
            responseInfo.respond('You must have tags.')
         else
            res = getMatchingNotes(tags)
            if (res.size() == 0)
               responseInfo.respond('No results.')
            else
               res.each{|note|
                  responseInfo.respond("Tags: [#{note[:tags]}]; Note: #{note[:note]}")
               }
            end
         end
      elsif (match = args.match(/^ADD\s+([^!]*)\s*!\s*(.+)$/i))
         tags = match[1].split(/\s+/)
         note = match[2].strip

         if (insertNote(note, tags))
            responseInfo.respond('Successfully added note.')
         else
            responseInfo.respond('There was an error adding the note.')
         end
      else
         responseInfo.respond('What? Try: HELP NOTE')
      end
   end
end

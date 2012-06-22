#TODO: Better tag matching
# Right now it tries to match all the tags

#TODO: query

class Note < Command
   include DB
   include RateLimit

   def initialize
      super('NOTE',
            'NOTE TAGS; ADD <tags> ! <note>; NOTE SEARCH <tags>; NOTE DETAILS <note number>' +
            ' NOTE REMOVE <note number>; NOTE EDIT <note number> <tags> ! <note>',
            'See the currently used TAGS; ADD a note; or SEARCH through notes using tags;' + 
            ' REMOVE a note; EDIT a note (this is esentially a replacement). Tags should be whitespace seperated.')
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

   def removeNote(id)
      begin
         db.query("DELETE FROM #{NOTES_TABLE} WHERE id = #{id}")
         db.query("DELETE FROM #{NOTE_TAGS_TABLE} WHERE note_id = #{id}")
         return true
      rescue Exception => ex
         puts ex.message
         return false
      end
      return false
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

   def replaceNote(id, note, tags)
      begin
         db.query("REPLACE INTO #{NOTES_TABLE} (id, note) VALUES (#{id}, '#{escape(note)}')")
         db.query("DELETE FROM #{NOTE_TAGS_TABLE} WHERE note_id = #{id}")

         insert = "INSERT IGNORE INTO #{NOTE_TAGS_TABLE} (note_id, tag) VALUES "
         tags.each{|tag|
            insert += "(#{id}, '#{escape(tag)}'), "
         }
         insert.sub!(/, $/, '')

         db.query(insert)
         return true
      rescue Exception => ex
         puts ex.message
         return false
      end
      return false
   end

   def getMatchingNotes(tags)
      tagStr = ''
      tags.each{|tag|
         tagStr += "'#{escape(tag)}', "
      }
      tagStr.sub!(/, $/, '')

      res = db.query("SELECT n.id, n.note, tags.tags, n.author, n.timestamp" +
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
            notes << {:id => row[0], :note => row[1], :tags => row[2],
                      :author => row[3], :timestamp => row[4].to_i}
         }
      end

      return notes
   end

   def getNote(id)
      res = db.query("SELECT n.id, n.note, tags.tags, n.author, n.timestamp" +
                     " FROM" +
                     " #{NOTES_TABLE} n" +
                     " JOIN (" +
                     "   SELECT note_id, GROUP_CONCAT(tag ORDER BY tag SEPARATOR ', ') as tags" +
                     "   FROM #{NOTE_TAGS_TABLE}" + 
                     "   WHERE note_id = #{id}" + 
                     "   GROUP BY note_id" +
                     " ) tags ON tags.note_id = n.id")
      
      if (!res || res.num_rows() == 0)
         return nil
      else
         row = res.fetch_row()
         return {:id => row[0], :note => row[1], :tags => row[2],
                 :author => row[3], :timestamp => row[4].to_i}
      end
   end

   def onCommand(responseInfo, args)
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
                  responseInfo.respond("Note ##{note[:id]} -- Tags: [#{note[:tags]}]; Note: #{note[:note]}")
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
      elsif (match = args.match(/^DETAILS\s+(\d+)$/i))
         if (note = getNote(match[1].to_i))
            message = "Id: #{note[:id]}, Author: #{note[:author]}," +
                      " Time: #{Time.at(note[:timestamp])}, Tags: [#{note[:tags]}]"
            responseInfo.respond(message)
         else
            responseInfo.respond('Unable to find that note.')
         end
      elsif (match = args.match(/^REMOVE\s+(\d+)$/i))
         if (removeNote(match[1].to_i))
            responseInfo.respond('Note successfully removed.')
         else
            responseInfo.respond('There was an error removing the note, does it exist?')
         end
      elsif (match = args.match(/^EDIT\s+(\d+)\s+([^!]*)\s*!\s*(.+)$/i))
         number = match[1].to_i
         tags = match[2].split(/\s+/)
         note = match[3].strip

         if(replaceNote(number, note, tags))
            responseInfo.respond('Successfully edited note.')
         else
            responseInfo.respond('There was an error editing the note.')
         end
      else
         responseInfo.respond('What? Try: HELP NOTE')
      end
   end
end

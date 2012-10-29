# encoding: UTF-8

# http://en.wikipedia.org/wiki/<target>

require 'date'

require 'nokogiri'
require 'open-uri'

# Get articles on wikipedia
class WikiFetcher
   extend ClassUtil

   RELOADABLE_CONSTANT('BASE_URL', 'http://en.wikipedia.org/wiki/')
   RELOADABLE_CLASS_VARIABLE('@@cache', {})

   def self.lookup(target)
      normalTarget = normalizeTarget(target)

      if (@@cache.has_key?(normalTarget))
         return @@cache[normalTarget]
      end

      doc = getTarget(normalTarget)
      if (doc)
         @@cache[normalTarget] = doc
      end

      return doc
   end

 private

   def self.getTarget(target)
      rtn = {:doc => nil,
             :firstPara => nil, :cleanFirstPara => nil,
             :box => nil, :bday => nil}
      firstParaPath = '//div[@id="mw-content-text"]/p[1]'
      vboxPath = '//div[@id="mw-content-text"]/table[starts-with(@class, "infobox")]'

      begin
         doc = Nokogiri::HTML(open(BASE_URL + target))
         rtn[:doc] = doc

         rtn[:firstPara] = doc.xpath(firstParaPath).to_s
         if (rtn[:firstPara])
            rtn[:cleanFirstPara] = cleanPara(rtn[:firstPara])
         end

         rtn[:box] = doc.xpath(vboxPath).to_s
         if (rtn[:box])
            rtn[:bday] = getBDay(rtn[:box])
         end
      rescue Exception => ex
         #puts ex.message
         #puts ex.backtrace.inspect
         log(ERROR, ex.message)
         log(ERROR, ex.backtrace.inspect)
         return nil
      end

      return rtn
   end

   def self.getBDay(box)
      # Boxes have special tags: <span class="bday">1735-10-30</span>
      match = box.match(/\<span\s+class="bday"\>(\d+-\d+-\d+)\<\/span\>/)
      if (match)
         return Date.parse(match[1]).strftime('%B %-d, %Y')
      end

      match = box.match(/Born((?:(?!\<\/tr\>).)*)\<\/tr\>((?:(?!\<\/tr\>).)*)\<\/tr\>/m)
      if (!match)
         return nil
      end

      bornCell = match[1]

      # First look for ones int the format: October 30, 1735
      # Then look for: 1735-10-30
      match = bornCell.match(/([A-Z][a-z]+\s+\d\d?,\s+\d\d\d\d)/)
      if (match)
         # No format necessary
         return match[1]
      end

      match = bornCell.match(/(\d\d\d\d-\d\d?-\d\d?)/)
      if (match)
         return Date.parse(match[1]).strftime('%B %-d, %Y')
      end

      return nil
   end

   def self.cleanPara(text)
      # Remove some
      clean = text.gsub(/\<\/?(p|b)\>/, ' ')

      # Keep the inner parts on some
      ['a', 'sup', 'span', 'i', 'small'].each{|tag|
         #clean = clean.gsub(/\<#{tag}[^\>]*\>((?:(?!\<#{tag}[^\>]*\>).)*)\<\/#{tag}\>/, ' \1 ')
         clean = clean.gsub(/\<\/?#{tag}[^\>]*\>/, ' ')
      }

      # Remove cites
      clean = clean.gsub(/\[\s*\d+\s*\]/, ' ')

      # Somewhere along the line, unicodes get replaced with multiple ?'s, remove them.
      clean = clean.gsub(/\?\?+/, ' ')

      # Condense spaces
      clean = clean.gsub(/\s+/, ' ')

      # Fix improperly spaced punctuation
      clean = clean.gsub(/\s([\.!\?,;\)])/, '\1')
      clean = clean.gsub(/([\(\[])\s/, '\1')
      clean = clean.gsub(/(\w+)\s*-\s*(\w+)/, '\1-\2')

      return clean.strip()
   end

   def self.normalizeTarget(target)
      return target.strip.gsub(/\s+/, '_')
   end
end

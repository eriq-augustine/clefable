# TODO: Right now it is only looking for spaces
# TODO: Doesn't deal well when there are no spaces in split
module TextSplit
   def splitText(text, length = MAX_MESSAGE_LEN)
      splits = Array.new()
      cursor = 0

      while (cursor < text.length)
         fineCursor = cursor + length

         if (fineCursor >= text.length)
            splits << text[cursor, text.length]
            break
         end

         while (fineCursor > cursor && text[fineCursor] != ' ')
            fineCursor -= 1
         end

         # Just take the whole split without breaks.
         if (fineCursor == cursor)
            fineCursor = cursor + length
         end

         splits << text[cursor...fineCursor]

         cursor = fineCursor + 1
      end

      return splits
   end
end

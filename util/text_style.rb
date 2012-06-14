module TextStyle
   META_COLOR_CHAR = 3.chr()
   META_BOLD_CHAR = 2.chr()
   META_NORMAL_CHAR = 15.chr()

   BLACK = '01'
   GREEN = '03'
   RED = '04'
   YELLOW = '08'

   def styleText(text, textStyle, returnStyle)
      return "#{textStyle}#{text}#{returnStyle}"
   end

   def colorText(text, color, returnColor = BLACK)
      return "#{META_COLOR_CHAR}#{styleText(text, color, META_COLOR_CHAR)}#{returnColor}"
   end

   def bold(text)
      return styleText(text, META_BOLD_CHAR, META_NORMAL_CHAR)
   end

   def green(text)
      return colorText(text, GREEN)
   end

   def red(text)
      return colorText(text, RED)
   end

   def yellow(text)
      return colorText(text, YELLOW)
   end
end

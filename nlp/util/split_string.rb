# Split a string
def nlpSplitString(text)
   return text.split()
end

# Naive Split
# Fuck it, 3 part replace.
def nlpSentenceSplit(text)
   rtn = []

   periodReplace = '@@'
   periodRegex = /((?:P)|(?:S)|(?:Mr)|(?:Mrs)|(?:Ms)|(?:Mme)|(?:Sta)|(?:Sr)|(?:Sra)|(?:Dr))\./

   text.gsub(/[\s\n]+/, ' ').strip().gsub(periodRegex, '\1' + "#{periodReplace}").gsub(/([\.\!\?])/, '\1' + "\n").each_line{|sentence|
      rtn << sentence.strip().gsub(/#{periodReplace}/, '.')
   }

   return rtn
end

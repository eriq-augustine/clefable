# util must be loaded first.

Dir['./common/util/*.rb'].each{|file|
   require file
}

Dir['./common/commands/*.rb'].each{|file|
   require file
}

Dir['./common/*.rb'].each{|file|
   require file
}

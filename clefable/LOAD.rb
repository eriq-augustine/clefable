Dir['./clefable/config/*.rb'].each{|file|
   require file
}

Dir['./clefable/util/*.rb'].each{|file|
   require file
}

Dir['./clefable/commands/*.rb'].each{|file|
   require file
}

Dir['./clefable/*.rb'].each{|file|
   require file
}

class Mongo::Collection

  def last
    find_one({}, { :sort => [:$natural, :desc] })
  end

end

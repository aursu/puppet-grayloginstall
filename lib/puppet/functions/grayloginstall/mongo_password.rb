Puppet::Functions.create_function(:'grayloginstall::mongo_password') do
  dispatch :mongo_password do
    param 'String', :pw
  end

  # If the username or password includes the at sign @, colon :, slash /, or
  # the percent sign % character, use percent encoding
  def mongo_password(pw)
    pw.gsub('%', '%25')
      .gsub('@', '%40')
      .gsub(':', '%3A')
      .gsub('/', '%2F')
  end
end

module FilterTokenPath
  CANCEL_PATH = %r{\A/a/[^/?]+}

  def filtered_path = super.sub(CANCEL_PATH, "/a/[FILTERED]")
end

ActionDispatch::Request.prepend(FilterTokenPath)

#require File.expand_path('../../../util/ini_file', __FILE__)

Puppet::Type.type(:cfg).provide(:cfg) do
  optional_commands(
    :sed => "/bin/sed"
  )

  def exists?
    get_value(key)
  end

  def create
    set_value(key, resource[:value])
  end

  def destroy
    if exists?
      sed("-ire", "/^\s*#{key}\s*#{separator_char}.*$/D", file)
    end
  end

  def key
    resource[:key].to_sym
  end

  def value
    get_value(key)
  end

  def value=(value)
    set_value(key, value)
  end

  def separator_char
    resource[:key_val_separator_char] || '='
  end

  def comment_char
    resource[:comment_char] || '#'
  end

  def file
    resource[:file]
  end

  private

  def set_value(key, val)
    config = parse_file(file)
    if not config.has_key?(key)
      add_value(key, val)
    else
      sed("-ire", "s/^\s*#{key}\s*#{separator_char}.*$/#{key}#{separator_char}#{val}/", file)
    end
  end

  def add_value(key, val)
    config = parse_file(file)
    if config.has_key?(key)
      set_value(key, val)
    else
      File.open(file, 'a') do |fh|
        line = "#{key}#{separator_char}#{val}\n"
        fh.puts(line)
      end
    end
  end

  def get_value(key)
    config = parse_file(file)
    if config.has_key?(key)
      rv = config[key]
    else
      rv = nil
    end
    #print(config)
    return rv
  end

  def parse_file(filename)
    rv = {}
    File.open(filename, 'r') do |fh|
      while line = fh.gets 
        if line_gr = line.match(/^\s*([\w\-_]+)\s*#{separator_char}\s*(.*)\s*$/o)
          key, pre_val = line_gr.captures
          if val_g = pre_val.match(/(.*)(\s*#{comment_char}.*)/o)
            val = val_g.captures[0]
          else
            val = pre_val
          end
          val = val.sub(/\s*$/,'')
          rv[key.to_sym] = val
        end
      end
    end
    return rv
  end 
end

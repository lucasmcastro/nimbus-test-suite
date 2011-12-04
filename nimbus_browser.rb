# encoding: utf-8
require "watir-webdriver"
require "yaml"

class NimbusBrowser < Watir::Browser
  attr_accessor :config

  def initialize(browser = :chrome, *args)
    parse_config
    super(browser, *args)
  end

  def goto(uri, base_url=self.base_url)
    if uri =~ URI.regexp
      super(uri)
    else
      super(base_url+uri)
    end
  end

  # Network Wizard causes IP to change
  # Use this after the wizard
  def goto_base
    self.goto ""
  end

  # Use this before the wizard
  # Since Network Wizard didn't change IP yet
  def goto_start
    self.goto("", self.start_url)
  end

  def base_url
    "http://#{self.config['nimbus_ip']}/"
  end
  
  def start_url
    "http://#{self.config['initial_ip']}/"
  end
  
  def parse_config
      self.config = open('config.yml') {|f| YAML.load(f)}
  end

  def nimbus_login
    self.goto "session/login"
    self.auto_fill :nimbus_login
    self.button(:text => 'Acessar').click
  end

  def auto_fill(data_set_name)
    data_dict = self.config[data_set_name.to_s]
    for type,data in data_dict 
      self.fill(type, data)
    end
  end

  def fill(type, data)
    setter = find_setter(type)
    for name,value in data
      field = self.get_field type, name
      begin
        field.send "#{setter}", value
      rescue Watir::Exception::UnknownObjectException
        raise  UnknownField, "Could not find #{type} with name '#{name}'"
      end
    end
  end

  def get_field(type, name)
      self.send "#{type}", :name => "#{name}"
  end

  def find_setter(type)
    case type
      when 'text_field'
        'set'
      when 'select_list'
        'select'
    end
  end  
end

class UnknownField < Exception
end


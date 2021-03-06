# encoding: utf-8
require "watir-webdriver"
require "yaml"
require "time"

class NimbusBrowser < Watir::Browser
  attr_accessor :config

  def initialize(browser = :chrome, *args)
    parse_config
    super(browser, *args)
  end

  def goto(uri, ip_key=:after_wizard_ip)
    if uri =~ URI.regexp # something like http://fuck.yeah
      super(uri)
    else
      super(self.base_url(ip_key)+uri)
    end
  end

  def goto_base(ip_key=:after_wizard_ip)
    self.goto base_url(ip_key)
  end

  def base_url(ip_key=:after_wizard_ip)
    "http://#{self.config[ip_key.to_s]}/"
  end

  def menu(main_menu, option)
    self.link(:text => main_menu).wait_until_present
    self.link(:text => main_menu).click
    self.link(:text => option).wait_until_present
    self.link(:text => option).click
  end
    
  def nimbus_login(credentials=:login_credentials)
    self.goto_base
    self.auto_fill credentials
    self.button(:text => 'Acessar').click
  end

  def auto_fill(data_set_name)
    data_dict = self.config[data_set_name.to_s]
    for type,data in data_dict 
      self.fill(type, data)
    end
  end

  def get_current_time
    self.span(:id => "actual_time").text
  end

  def get_current_hour
    self.get_current_time.split(":")[0]
  end

  # Internals
  protected

  def parse_config
      self.config = open('config.yml') {|f| YAML.load(f)}
  end

  def get_field(type, name)
      self.send "#{type}", :name => "#{name}"
  end

  def fill(type, data)
    setter = find_setter(type)
    for name,value in data
      field = self.get_field type, name
      begin
        field.send "#{setter}", value
      rescue Watir::Exception::UnknownObjectException
        raise  UnknownField, "Could not find field '#{type}' with name '#{name}'"
      rescue NoMethodError
        raise UnknownSetter, "The field '#{type}' doesn't seem to have '#{setter}' setter"
      end
    end
  end

  def find_setter(type)
    case type
      when 'text_field'
        'set'
      when 'select_list'
        'select'
      when 'checkbox'
        'set'
      else
        raise  UnknownFieldType, "Could not find propper setter for '#{type}' field type"
    end
  end
end

class UnknownField < Exception
end

class UnknownFieldType < Exception
end

class UnknownSetter < Exception
end

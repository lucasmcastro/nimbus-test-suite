# encoding: utf-8
require "rubygems"
require "rspec"
require "watir-webdriver"
require "yaml"
require "ruby-debug"
require "net/http"

unless Process.uid == 0
  puts 'Must run as root'
  exit -1
end 

def parse_config
  begin
    refs = open('config.yml') {|f| YAML.load(f)}
  rescue Errno::ENOENT 
    puts "Could not find config.yml"
    exit -1
  end

  @nimbus_ip ||= refs['nimbus ip']
  @base_url ||= "http://#{@nimbus_ip}/"
end


def nimbus_login
end

describe "virgin nimbus" do
  let(:browser)       { @browser ||= Watir::Browser.new :chrome }

  before { parse_config; browser.goto @base_url }
  after { browser.close }

  it "should finish whole wizard" do
    browser.title.should == "Nimbus" # TODO: ask dev team to change this
    browser.h2.text.should == "1 DE 4 - LICENÇA"
    browser.button.click
    browser.h2.text.should == "2 DE 4 - CONFIGURAÇÃO DE REDE"
    browser.text_field(:name => 'address').set '172.16.241.133'
    browser.text_field(:name => 'netmask').set '255.255.255.0' 
    browser.text_field(:name => 'gateway').set '172.16.241.1'
    browser.text_field(:name => 'dns1').set '172.16.241.1'
    browser.text_field(:name => 'dns2').set '8.8.8.8'
    browser.button.click
    browser.h2.text.should == "3 DE 4 - CONFIGURAÇÃO DE HORA"
    browser.text_field(:name => 'ntp_server').set 'a.ntp.br'
    browser.select_list(:name => 'country').select 'Brazil'
    browser.select_list(:name => 'area').select 'America/Recife'
    browser.button.click
    browser.h2.text.should == "4 DE 4 - SENHA DO USUÁRIO ADMIN"
    browser.text_field(:name => 'new_password1').set 'admin'
    browser.text_field(:name => 'new_password2').set 'admin'
    browser.button.click
    browser.h2.text.should == "LOGIN • NIMBUS"
  end
end

describe "configured nimbus" do
  let(:browser)       { @browser ||= Watir::Browser.new :chrome }

  before { 
    parse_config
    browser.goto @base_url
    browser.text_field(:name => 'username').set 'admin'
    browser.text_field(:name => 'password').set 'admin'
    browser.button.click
  }
  after { browser.close }

  it "should add a client" do
    browser.h2.text.should == "BACKUPS" # dashboard
    system("nimbusnotifier admin admin #{@nimbus_ip}")
    browser.goto @base_url+"computers/add/"
    debugger
    browser.goto browser.link(:text => 'Editar').href
    browser.text_field(:name => 'name').set 'Client 1'
    browser.text_field(:name => 'description').set 'This machine was added by watir automated test.'
    browser.button(:text => 'Atualizar').click
    browser.goto browser.link(:text => 'Ativar').href #TODO: ask team to change to protect this action with POST
  end
end

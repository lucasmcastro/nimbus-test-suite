# encoding: utf-8
require "rubygems"
require "bundler/setup"
require "rspec"
# require "ruby-debug"
require "net/http"
require "nimbus_browser"

check_for_root

describe "virgin nimbus" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.goto "" }
  after { browser.close }

  it "should finish whole wizard" do
    browser.title.should == "Nimbus" # TODO: ask dev team to change this
    browser.h2.text.should == "1 DE 4 - LICENÇA"
    browser.button.click
    browser.h2.text.should == "2 DE 4 - CONFIGURAÇÃO DE REDE"
    browser.auto_fill :wizard_network
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
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.nimbus_login }
  after { browser.close }

  it "should add a client" do
    browser.h2.text.should == "BACKUPS" # dashboard
    system("nimbusnotifier admin admin #{@nimbus_ip}")
    browser.goto "computers/add/"
    browser.goto browser.link(:text => 'Editar').href
    browser.text_field(:name => 'name').set 'Client 1'
    browser.text_field(:name => 'description').set 'This machine was added by watir automated test.'
    browser.button(:text => 'Atualizar').click
    browser.goto browser.link(:text => 'Ativar').href #TODO: ask team to change to protect this action with POST
  end
end

def check_for_root
  unless Process.uid == 0
    puts 'Must run as root'
    exit -1
  end
end
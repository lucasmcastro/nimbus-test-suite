# encoding: utf-8
require "rubygems"
require "bundler/setup"
require "rspec"
require "open-uri"
require_relative "nimbus_browser"


unless Process.uid == 0
  puts 'Must be run as root'
  exit -1
end


describe "virgin nimbus" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.goto_start }
  after { browser.close }

  it "should finish whole wizard" do
    browser.title.should == "Nimbus" # TODO: ask dev team to change this
    browser.h2.text.should == "1 DE 5 - LICENÇA"
    browser.button(:text => "Concordo").click
    browser.h2.text.should == "2 DE 5 - CONFIGURAÇÃO DE REDE"
    browser.auto_fill :wizard_network
    browser.button(:text => "Próximo").click
    browser.h2(:text => "3 DE 5 - CONFIGURAÇÃO DO OFFSITE").wait_until_present
    browser.button(:text => "Próximo").click
    browser.h2(:text => "4 DE 5 - CONFIGURAÇÃO DE HORA").wait_until_present
    browser.h2.text.should == "4 DE 5 - CONFIGURAÇÃO DE HORA"
    browser.auto_fill :wizard_timezone
    browser.button(:text => "Próximo").click
    browser.h2.text.should == "5 DE 5 - SENHA DO USUÁRIO ADMIN"
    browser.auto_fill :wizard_password
    browser.button(:text => "Próximo").click
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
    browser.link(:text => 'Computadores').click
    browser.link(:text => 'Ativar novo computador').click
    browser.link(:text => 'Editar').click
    browser.auto_fill :edit_client1
    browser.button(:text => 'Atualizar').click
    browser.link(:text => 'Ativar').click #TODO: ask team to change to protect this action with POST
  end
end

# encoding: utf-8
require "rubygems"
require "bundler/setup"
require "rspec"
require_relative "nimbus_browser"

unless Process.uid == 0
  puts 'Must be run as root'
  exit -1
end


describe "virgin nimbus" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.goto_base :before_wizard_ip }
  after { browser.close }

  it "should finish whole wizard" do
    browser.title.should == "Nimbus" # TODO: ask dev team to change this
    browser.h2.text.should == "1 DE 5 - LICENÇA"
    browser.button(:text => "Concordo").click
    browser.h2.text.should == "2 DE 5 - CONFIGURAÇÃO DE REDE"
    browser.auto_fill :wizard_network
    browser.button(:text => "Próximo").click
    browser.h2(:text => "4 de 5 - Configuração de Hora").wait_until_present
    browser.auto_fill :wizard_timezone
    browser.button(:text => "Próximo").click
    browser.h2.text.should == "3 DE 5 - CONFIGURAÇÃO DO OFFSITE"
    browser.button(:text => "Próximo").click
    browser.h2.text.should == "5 DE 5 - SENHA DO USUÁRIO ADMIN"
    browser.auto_fill :wizard_password
    browser.button(:text => "Próximo").click
    browser.h2.text.should == "LOGIN • NIMBUS"
  end
end

describe "configured nimbus" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.goto_base }
  after { browser.close }

  it "should be able to login" do
    browser.nimbus_login    
    browser.h2.text.should == "BACKUPS" # dashboard
  end

  it "shold be able to logout" do
    browser.nimbus_login
    browser.link(:text => 'Sair').click
    browser.h2.text.should == "LOGIN • NIMBUS"
  end

  it "should display error at login failure" do
    browser.nimbus_login :wrong_login_credentials
    browser.h2.text.should == "LOGIN • NIMBUS"
    # TODO: check error message according to I18n 
  end
end


describe "backup featured nimbus" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.nimbus_login }
  after { browser.close }

  it "should be able to add a client" do
    nimbus_ip = browser.config['after_wizard_ip']
    system("nimbusnotifier admin admin #{nimbus_ip}")
    browser.refresh
    browser.link(:text => 'Existe um novo computador aguardando para ser ativado').click
    browser.link(:text => 'Editar').click
    browser.auto_fill :edit_client1
    browser.button(:text => 'Atualizar').click
    browser.link(:text => 'Ativar').click #TODO: ask team to change to protect this action with POST
    browser.div(:id => 'computers').text.include?('Client 1').should == true
  end

  it "should be able to add a backup to Client 1" do
    browser.link(:text => 'Computadores').click
    browser.link(:text => 'Listar computador').click #TODO: ask dev team to change to 'computadores'
    browser.link(:text => 'Client 1').click
    browser.link(:text => 'Criar Backup').click
    # Schedule
    browser.link(:text => 'Criar um agendamento').click
    browser.span(:text => 'Dom').wait_until_present
    browser.span(:text => 'Dom').click
    browser.link(:text => 'Agendamento Semanal').click
    #browser.link(:text => 'Criar Agendamento').wait_until_present
    browser.link(:text => 'Criar Agendamento').click
    browser.link(:text => 'Criar Agendamento').wait_while_present
    # FileSet
    browser.link(:text => 'Criar um conjunto de arquivos').wait_until_present
    browser.link(:text => 'Criar um conjunto de arquivos').click
    browser.span(:text => '/').wait_until_present    
    browser.span(:text => '/').click
    browser.span(:text => 'home/').wait_until_present
    browser.span(:text => 'home/').click
    browser.span(:text => 'aluno/').wait_until_present
    browser.span(:text => 'aluno/').click
    browser.checkbox(:value => '/home/aluno/Django/').wait_until_present
    browser.checkbox(:value => '/home/aluno/Django/').click
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.text_field(:name => 'procedure-name').set 'Watir BPK #1'
    browser.button(:text => 'Adicionar Backup').click
    browser.h3(:text => 'Watir BPK #1').exists?.should == true
  end

  it "should be able to add a fileset profile" do
    browser.link(:text => 'Backup').click
    browser.link(:text => 'Listar perfis de configuração').click
    browser.select(:id => 'select_fileset_new').select 'Client 1'
    browser.link(:text => 'Adicionar').click
    browser.span(:text => '/').wait_until_present    
    browser.span(:text => '/').click
    browser.span(:text => 'home/').wait_until_present
    browser.span(:text => 'home/').click
    browser.span(:text => 'aluno/').wait_until_present
    browser.span(:text => 'aluno/').click
    browser.checkbox(:value => '/home/aluno/Django/').wait_until_present
    browser.checkbox(:value => '/home/aluno/Django/').click
    browser.text_field(:name => 'fileset-name').set 'Fset Profile'
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.div(:class => 'fileset').text.include?('Fset Profile').should == true

  end

  it "should be able to add a fileset profile" do
    browser.link(:text => 'Backup').click
    browser.link(:text => 'Listar perfis de configuração').click
    browser.link(:class => 'css3button positive edit-schedule').click # TODO: Ask dev team to change this
    browser.span(:text => 'Dom').wait_until_present
    browser.span(:text => 'Dom').click
    browser.link(:text => 'Agendamento Semanal').click
    browser.text_field(:id => 'schedule_name').set 'Sched Profile'
    browser.link(:text => 'Criar Agendamento').click
    browser.link(:text => 'Criar Agendamento').wait_while_present    
    browser.div(:class => 'schedule').text.include?('Sched Profile').should == true
  end

  it "should be able to add a backup to Client 1 with profiles" do
    browser.link(:text => 'Computadores').click
    browser.link(:text => 'Listar computador').click #TODO: ask dev team to change to 'computadores'
    browser.link(:text => 'Client 1').click
    browser.link(:text => 'Criar Backup').click
    browser.auto_fill :backup_with_profiles
    browser.text_field(:name => 'procedure-name').set 'Watir BPK #2'
    browser.button(:text => 'Adicionar Backup').click
    browser.h3(:text => 'Watir BPK #2').exists?.should == true  
  end
end

describe "management featured nimbus" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.nimbus_login }
  after { browser.close }

  it "should be able to change timezone" do
    browser.link(:text => 'Configurações').click
    browser.link(:text => 'Configuração de Hora').click
    base_hour = browser.get_current_hour
    browser.auto_fill :edit_timezone
    browser.button(:text => 'Atualizar').click
    base_hour.to_i.should == browser.get_current_hour.to_i+1 # Shift for Argentina Timezone
    browser.auto_fill :undo_edit_timezone
    browser.button(:text => 'Atualizar').click
    base_hour.should == browser.get_current_hour
  end

  it "should be able to configure email notif1" do
    browser.link(:text => 'Configurações').click
    browser.link(:text => 'Notificações por email').click
    debugger
    browser.auto_fill :email_notif
    browser.button(:text => 'Atualizar').click
    browser.div(:class => 'message success').exists?.should == true
    browser.button.click
    browser.div(:class => 'message success').exists?.should == true     
  end
end

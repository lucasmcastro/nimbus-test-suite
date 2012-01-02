# encoding: utf-8
require "rubygems"
require "bundler/setup"
require "rspec"
require_relative "nimbus_browser"

# TODO: ask dev team to remove root need for notification
unless Process.uid == 0
  puts 'Must be run as root'
  exit -1
end

describe "Nimbus with wizard features" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.goto_base :before_wizard_ip }
  after { browser.close }

  it "should finish whole wizard" do
    # TODO: need better way to find this out
    browser.title.should == "Nimbus"
    browser.h2.text.should == "1 DE 5 - LICENÇA"
    browser.button(:text => "Concordo").click
    browser.h2.text.should == "2 DE 5 - CONFIGURAÇÃO DE REDE"
    browser.auto_fill :wizard_network
    browser.button(:text => "Próximo").click
    browser.h2(:text => "4 de 5 - Configuração de Hora").wait_until_present
    browser.auto_fill :wizard_timezone
    browser.button(:text => "Próximo").click
    browser.h2.text.should == "3 DE 5 - CONFIGURAÇÃO DO OFFSITE"
    browser.checkbox(:id => 'id_active').click
    browser.text_field(:name => 'username').wait_until_present
    browser.auto_fill :wizard_offsite
    browser.button(:text => "Próximo").click
    browser.h2.text.should == "5 DE 5 - SENHA DO USUÁRIO ADMIN"
    browser.auto_fill :wizard_password
    browser.button(:text => "Próximo").click
    browser.h2.text.should == "LOGIN • NIMBUS"
  end
end

describe "Nimbus with authentication features" do
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
    browser.ul(:class => 'errorlist').exists?.should == true
    # TODO: check error message according to I18n 
  end
end


describe "Nimbus with backup features" do
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
    # TODO: Ask dev team to protect 'Ativar' action with POST
    browser.link(:text => 'Ativar').click 
    browser.h3(:text => 'Client 1').exists?.should == true
  end

  it "should be able to add a backup to Client 1" do
    browser.menu 'Computadores', 'Listar computador'
    # TODO: ask dev team to change to 'Listar computadores'
    browser.link(:text => 'Client 1').click
    browser.link(:text => 'Criar Backup').click
    # Schedule
    browser.link(:text => 'Criar um agendamento').click
    browser.span(:text => 'Dom').wait_until_present
    browser.span(:text => 'Dom').click
    browser.link(:text => 'Agendamento Semanal').click
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
    browser.checkbox(:value => '/home/aluno/Downloads/').wait_until_present
    browser.checkbox(:value => '/home/aluno/Downloads/').click
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.text_field(:name => 'procedure-name').set 'Watir BKP #1'
    browser.button(:text => 'Adicionar Backup').click
    browser.h3(:text => 'Watir BKP #1').exists?.should == true
  end

  it "should be able to add a fileset profile" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    browser.select(:id => 'select_fileset_new').select 'Client 1'
    browser.link(:text => 'Adicionar').click
    browser.span(:text => '/').wait_until_present
    browser.span(:text => '/').click
    browser.span(:text => 'home/').wait_until_present
    browser.span(:text => 'home/').click
    browser.span(:text => 'aluno/').wait_until_present
    browser.span(:text => 'aluno/').click
    browser.checkbox(:value => '/home/aluno/Downloads/').wait_until_present
    browser.checkbox(:value => '/home/aluno/Downloads/').click
    browser.text_field(:name => 'fileset-name').set 'Fset Profile'
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.div(:class => 'fileset').text.include?('Fset Profile').should == true

  end

  it "should be able to add a schedule profile" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    browser.link(:class => 'css3button positive edit-schedule').click 
    # TODO: need better way to select this edit schedule link
    browser.span(:text => 'Dom').wait_until_present
    browser.span(:text => 'Dom').click
    browser.link(:text => 'Agendamento Semanal').click
    browser.text_field(:id => 'schedule_name').set 'Sched Profile'
    browser.link(:text => 'Criar Agendamento').click
    browser.link(:text => 'Criar Agendamento').wait_while_present    
    browser.div(:class => 'schedule').text.include?('Sched Profile').should == true
  end

  it "should be able to add a backup to Client 1 with profiles" do
    browser.menu 'Computadores', 'Listar computador'
    # TODO: ask dev team to change to 'Listar computadores'
    browser.link(:text => 'Client 1').click
    browser.link(:text => 'Criar Backup').click
    browser.auto_fill :backup_with_profiles
    # TODO: check if this text_field can go to config.yml
    browser.text_field(:name => 'procedure-name').set 'Watir BKP #2'
    browser.button(:text => 'Adicionar Backup').click
    browser.h3(:text => 'Watir BKP #2').exists?.should == true  
  end

  it "should be able to do a successfull backup" do
    browser.menu 'Backup', 'Listar procedimentos'
    browser.button(:text => 'Executar Agora').click
    until(browser.span(:class => 'status_running').exists?) do
      browser.refresh
    end
    while(browser.span(:class => 'status_running').exists?) do
      browser.refresh
    end
    browser.span(:class => 'status_ok').exists?.should == true  
  end
end

describe "Nimbus with management features" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.nimbus_login }
  after { browser.close }

  it "should be able to change timezone" do
    browser.menu 'Configurações', 'Configuração de Hora'
    base_hour = browser.get_current_hour
    browser.auto_fill :edit_timezone
    browser.button(:text => 'Atualizar').click
    # Check for time shift (+1)
    base_hour.to_i.should == browser.get_current_hour.to_i+1 
    browser.auto_fill :undo_edit_timezone
    browser.button(:text => 'Atualizar').click
    base_hour.should == browser.get_current_hour
  end

  it "should be able to change password" do
    browser.menu 'Configurações', 'Alterar Senha'
    browser.auto_fill :edit_password
    browser.button(:text => 'Atualizar').click
    browser.div(:class => 'message success').exists?.should == true     
    browser.link(:text => 'Sair').click
    browser.h2.text.should == "LOGIN • NIMBUS"
    browser.nimbus_login
    browser.h2.text.should == "LOGIN • NIMBUS"
    browser.ul(:class => 'errorlist').exists?.should == true
    browser.nimbus_login :changed_credentials
    browser.link(:text => 'Configurações').click
    browser.link(:text => 'Alterar Senha').click
    browser.auto_fill :undo_edit_password
    browser.button(:text => 'Atualizar').click
    browser.div(:class => 'message success').exists?.should == true     
  end

  it "should be able to configure email notification" do
    browser.menu 'Configurações', 'Notificações por email'
    browser.auto_fill :email_notif
    browser.button(:text => 'Atualizar').click
    browser.div(:class => 'message success').exists?.should == true
    browser.button.click
    browser.div(:class => 'message success').exists?.should == true     
  end

  it "should display errors at wrong host for email notification" do
    browser.menu 'Configurações', 'Notificações por email'
    browser.auto_fill :email_notif
    browser.text_field(:name => 'email_host').set 'wronghost.com'
    browser.button(:text => 'Atualizar').click
    browser.div(:class => 'message success').exists?.should == true
    browser.button.click
    browser.div(:class => 'message error').exists?.should == true     
  end

  it "should display errors at wrong password for email notification" do
    browser.menu 'Configurações', 'Notificações por email'
    browser.auto_fill :email_notif
    browser.text_field(:name => 'email_password').set 'wrong'
    browser.button(:text => 'Atualizar').click
    browser.div(:class => 'message success').exists?.should == true
    browser.button.click
    browser.div(:class => 'message error').exists?.should == true     
  end

  it "should be able to see about nimbus" do
    browser.menu 'Ajuda', 'Sobre o Nimbus'
    browser.link(:href => '/LICENSE/').wait_until_present
    browser.link(:href => '/LICENSE/').exists?.should == true
  end
end

describe "Nimbus with edit objects features" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.nimbus_login }
  after { browser.close }

  it "should be able to edit computer" do
    browser.menu 'Computadores', 'Listar computador'
    browser.link(:text => 'Editar').click
    browser.text_field(:name => 'name').set 'Client Changed'
    browser.button(:text => 'Atualizar').click
    browser.h3(:text => 'Client Changed').exists?.should == true
    browser.link(:text => 'Editar').click
    browser.text_field(:name => 'name').set 'Client 1'
    browser.button(:text => 'Atualizar').click
    browser.h3(:text => 'Client 1').exists?.should == true
  end

  it "should be able to edit backup procedure" do
    browser.menu 'Backup', 'Listar procedimentos'
    browser.link(:text => 'Editar').click
    browser.text_field(:name => 'procedure-name').set 'Backup Changed'
    browser.button(:text => 'Salvar').click
    browser.h3(:text => 'Backup Changed').exists?.should == true
    browser.link(:text => 'Editar').click
    browser.text_field(:name => 'procedure-name').set 'Watir BKP #1'
    browser.button(:text => 'Salvar').click
  end

  it "should be able to edit schedule profile (adding)" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    browser.div(:class => 'schedule').link(:text => 'Editar').click
    browser.span(:text => 'Sáb').wait_until_present
    browser.span(:text => 'Sáb').click
    browser.link(:text => 'Agendamento Semanal').click
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.div(:class => 'schedule').text.include?('Sabado').should == true
  end

  it "should be able to edit schedule profile (removing)" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    browser.div(:class => 'schedule').link(:text => 'Editar').click
    browser.span(:text => 'Dom').wait_until_present
    # TODO: need better way to click at this images
    # this is a workaround because it was not possible to iter
    # through all images idk why
    # maybe this is related to the way javascript is dealing
    # with this images, its causing some how to remove it from the DOM
    # the better way to do this would be something like
    #    browser.img(:alt => 'Excluir').click
    #    browser.img(:alt => 'Excluir').click
    browser.images[2].click 
    browser.images[3].click
    browser.span(:text => 'Dom').click
    browser.link(:text => 'Agendamento Semanal').click
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.div(:class => 'schedule').text.include?('Sabado').should == false
  end

  it "should be able to edit fileset profile (adding)" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    fset_div = browser.div(:class => 'fileset')
    fset_div.select(:class => 'computer-fileset').select 'Client 1'
    fset_div.link(:text => 'Editar').click
    browser.span(:text => '/').wait_until_present
    browser.span(:text => '/').click
    browser.checkbox(:value => '/tmp/').wait_until_present
    browser.checkbox(:value => '/tmp/').click
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.div(:class => 'fileset').text.include?('/tmp/').should == true
  end

  it "should be able to edit fileset profile (removing)" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    fset_div = browser.div(:class => 'fileset')
    fset_div.select(:class => 'computer-fileset').select 'Client 1'
    fset_div.link(:text => 'Editar').click
    browser.span(:text => '/').wait_until_present
    browser.checkbox(:id => 'id_files-1-DELETE').click
    browser.button(:text => 'Salvar').click
    browser.button(:text => 'Salvar').wait_while_present
    browser.div(:class => 'fileset').text.include?('/tmp/').should == false
  end

  it "should be able to still do a successfull backup after backup changes" do
    browser.menu 'Backup', 'Listar procedimentos'
    browser.button(:text => 'Executar Agora').click
    until(browser.span(:class => 'status_running').exists?) do
      browser.refresh
    end
    while(browser.span(:class => 'status_running').exists?) do
      browser.refresh
    end
    browser.span(:class => 'status_ok').exists?.should == true  
  end
end

describe "Nimbus with remove objects features" do
  let(:browser)       { @browser ||= NimbusBrowser.new }

  before { browser.nimbus_login }
  after { browser.close }

  it "should be able to remove schedule profile" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    browser.div(:class => 'schedule').link(:text => 'Excluir').click
    # TODO: Ask dev team to protect 'Excluir' action with POST
    browser.link(:text => 'Excluir').click 
    browser.div(:class => 'schedule').text.include?('Sched Profile').should == false
  end

  it "should be able to remove fileset profile" do
    browser.menu 'Backup', 'Listar perfis de configuração'
    browser.div(:class => 'fileset').link(:text => 'Excluir').click
    # TODO: Ask dev team to protect 'Excluir' action with POST
    browser.link(:text => 'Excluir').click
    browser.div(:class => 'schedule').text.include?('Fset Profile').should == false
  end

  it "should be able to remove backup procedure" do
    browser.menu 'Backup', 'Listar procedimentos'
    browser.link(:text => 'Remover').click
    # TODO: Ask dev team to protect 'Excluir' action with POST
    browser.link(:text => 'Excluir').click 
    browser.link(:text => 'Remover').click
    # TODO: Ask dev team to protect 'Excluir' action with POST
    browser.link(:text => 'Excluir').click
    browser.h3(:text => 'Watir BKP #1').exists?.should == false
    browser.h3(:text => 'Watir BKP #2').exists?.should == false
  end

  it "should be able to remove computer" do
    browser.menu 'Computadores', 'Listar computador'
    browser.link(:text => 'Remover').click
    # TODO: Ask dev team to protect 'Excluir' action with POST
    browser.link(:text => 'Excluir').click
    browser.h3(:text => 'Client 1').exists?.should == false
  end
end





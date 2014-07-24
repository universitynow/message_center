class MessageCenter::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  def create_initializer_file
    template 'initializer.rb', 'config/initializers/message_center.rb'
  end

  def copy_migrations
    Rails.application.load_tasks
    Rake::Task['message_center:install:migrations'].invoke
  end

end

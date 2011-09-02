#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Provider:: unicorn
#
# Copyright:: 2011, Opscode, Inc <legal@opscode.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :before_compile do
  new_resource.restart_command "/etc/init.d/#{new_resource.id} hup" if !new_resource.restart_command
end

action :before_deploy do
end

action :before_migrate do
end

action :before_symlink do
end

action :before_restart do
  return # Don't want to fix things yet

  new_resource = @new_resource

  node.default[:unicorn][:preload_app] = false
  node.default[:unicorn][:worker_processes] = [node[:cpu][:total].to_i * 4, 8].min
  node.default[:unicorn][:preload_app] = false
  node.default[:unicorn][:before_fork] = 'sleep 1' 
  node.default[:unicorn][:port] = '8080'
  node.set[:unicorn][:options] = { :tcp_nodelay => true, :backlog => 100 }

  unicorn_config "/etc/unicorn/#{new_resource.id}.rb" do
    listen({ node[:unicorn][:port] => node[:unicorn][:options] })
    working_directory ::File.join(new_resource.path, 'current')
    worker_timeout new_resource.worker_timeout 
    preload_app node[:unicorn][:preload_app] 
    worker_processes node[:unicorn][:worker_processes]
    before_fork node[:unicorn][:before_fork] 
  end

  runit_service new_resource.id do
    template_name 'unicorn'
    cookbook 'application'
    options(
      :app => app,
      :rails_env => new_resource.environment_name,
      :smells_like_rack => ::File.exists?(::File.join(new_resource.path, "current", "config.ru"))
    )
    run_restart false
  end

end

action :after_restart do
end

Vagrant.configure("2") do |config|
  config.vm.box = "bento/amazonlinux-2023"
  config.vm.hostname = "cloudbyte"

  config.vm.provider "virtualbox" do |vb|
    vb.name   = "cloudbyte-linux-project"
    vb.cpus   = 2
    vb.memory = 2048
  end
end

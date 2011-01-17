# Class: apache
#
# This class manages apache vhosts.
#
# Parameters:
#   $apache_port
#       the port apache should listen on
#
#
# Actions:
#   Manages apache and apache vhosts.
#
# Requires:
#   - Package["apache2"]
#
# Sample Usage:
#
#   include "apache"
#
#   apache::vhost { "foo.bar.com":
#       vhost => "foo",
#       domain => "bar.com",
#       aliases => ["*.bar.com", "bar.com"],
#       packages => ["libapache2-mod-php5", "php5-mysql"]
#   }

class apache {
	package{ "apache2": ensure => installed }

	if $apache2_port {
		$port = $apache2_port
	} else {
		$port = "80"
	}

	service { apache2:
		ensure => running,
		enable => true,
	}

	file{"/etc/apache2/ports.conf":
		ensure => present,
		content => template("apache/ports.conf.erb")
	}

	file{["/etc/apache2/sites-available/default", "/etc/apache2/sites-enabled/000-default"]:
		ensure => absent
	}

	dir{$vhosts:
		dir => "/var/log/apache2",
	}

	define dir($dir){
		file{"$dir/$name":
			ensure => directory,
			owner => root,
			group => root,
			before => Service["apache2"],
		}
	}

	define vhost($vhost, $domain, $aliases=[], $packages=[], $port=$port){
		$linkname = "${name}.conf"

		file{"/etc/apache2/sites-available/${name}.conf":
			owner => root,
			group => root,
			mode => 0444,
			content => template("apache/vhost.conf.erb"),
			notify => Service["apache2"],
			before => File["/etc/apache2/sites-enabled/$linkname"]
		}

		file{"/etc/apache2/sites-enabled/$linkname":
			owner => root,
			group => root,
			mode => 0444,
			ensure => "/etc/apache2/sites-available/${name}.conf",
			notify => Service["apache2"]
		}

		package{$packages:
			ensure => latest,
			notify => Service["apache2"],
		}

	}

}

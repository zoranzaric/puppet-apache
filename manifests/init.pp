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

	define vhost($vhost, $domain, $aliases=[], $catchall=false, $packages=[]){
		include apache

		$port = $apache::port

		if $catchall {
			$linkname = "000-${name}.conf"
		} else {
			$linkname = "${name}.conf"
		}

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

		file{"/var/www/${domain}/${vhost}/configs/apache.conf":
			owner => root,
			group => root,
			mode => 0644,
			ensure => 'present',
			notify => Service["apache2"]
		}

		package{$packages:
			ensure => latest,
			notify => Service["apache2"],
		}

	}

}

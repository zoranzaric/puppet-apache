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

class apache {
	$packages = [ "libapache2-mod-php5", "libapache2-mod-wsgi", "php5-gd", "php5-mysql", "php5-ldap", "python-ldap", "python-mysqldb","libnet-ldap-perl"]

	package{ apache2: ensure => installed }

	if $apache2_port {
		$port = $apache2_port
	} else {
		$port = "80"
	}

	service { apache2:
		ensure => running,
		enable => true,
	}

	package{$packages:
		ensure => installed,
		notify => Service["apache2"],
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

	define vhost($vhost, $domain){
		$linkname = "${name}.conf"

		file{"/var/www/${domain}/":
			ensure => directory
		}
		file{"/var/www/${domain}/${vhost}/":
			ensure => directory
		}
		file{"/var/www/${domain}/${vhost}/htdocs/":
			ensure => directory
		}
		file{"/var/www/${domain}/${vhost}/logs/":
			ensure => directory
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
	}

}

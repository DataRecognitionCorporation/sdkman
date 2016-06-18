# == Define: sdkman::package
#
# Manages Sdkman packages. Installing or removing them.

# === Parameters
#
#
# [*is_version*]
#
# Informe if version should be set as default by sdkman
#
# [*version*]
# The version of package itself
#
# [*name*]
# Name of the given package being managed. If not present, title is used.
#

define sdkman::package (
   $version,
   $package_name = $name,
   $is_default   = false,
   $ensure       = present,
   $timeout      = 0 # disabled by default instead of 300 seconds defined by Puppet
){

   #$sdkman_init = "source $sdkman::user_home/.sdkman/bin/sdkman-init.sh"
   $sdkman_init = "$sdkman::user_home/.sdkman/bin/sdkman-init.sh"
   $package_path = "$sdkman::user_home/.sdkman/candidates/$package_name/$version"

   $sdkman_operation_unless = $ensure ? {
      present => "test -d $sdkman::user_home/.sdkman/candidates/$package_name/$version",
      absent  => "[ ! -d $sdkman::user_home/.sdkman/candidates/$package_name/$version ]",
   }

   $sdkman_operation = $ensure ? {
      present => "install",
      absent  => "rm"
   }                
   file { "$sdkman::user_home/.sdkman/bin/sdkman_${package_name}_${version}.sh":
      ensure  => file,
      owner   => $sdkman::owner,
      group   => $sdkman::group,
      mode    => '0755',
      content => template('sdkman/sdkman_script.sh.erb'),
      require => Class['sdkman'],
   }

   exec { "sdk $sdkman_operation $package_name $version" :
      environment => $sdkman::base_env,
      command     => "$sdkman::user_home/.sdkman/bin/sdkman_${package_name}_${version}.sh",
      unless      => $sdkman_operation_unless,
      cwd         => $sdkman::user_home,
      user        => $sdkman::owner,
      group       => $sdkman::group,
      path        => '/usr/bin:/usr/sbin:/bin',
      logoutput   => true,
      timeout     => $timeout,
      require     => [Class['sdkman'], File["$sdkman::user_home/.sdkman/bin/sdkman_${package_name}_${version}.sh"]],
      notify      => Exec["Remove $sdkman::user_home/.sdkman/bin/sdkman_${package_name}_${version}.sh"],
      provider    => shell,
   }

   exec { "Remove $sdkman::user_home/.sdkman/bin/sdkman_${package_name}_${version}.sh":
      command => "rm -f $sdkman::user_home/.sdkman/bin/sdkman_${package_name}_${version}.sh",
      cwd     => $sdkman::user_home,
      user    => $sdkman::owner,
      group   => $sdkman::group,
      onlyif  => "test -f $sdkman::user_home/.sdkman/bin/sdkman_${package_name}_${version}.sh",
      path    => '/usr/bin:/usr/sbin:/bin',
      provider    => shell,
   }
   
   if $ensure == present and $is_default {
      file { "$sdkman::user_home/.sdkman/bin/sdkman_default_${package_name}_${version}.sh":
         ensure  => file,
         owner   => $sdkman::owner,
         group   => $sdkman::group,
         mode    => '0755',
         content => template('sdkman/sdkman_default.sh.erb'),
         require => Class['sdkman'],
      }

      exec {"sdk default $package_name $version" :
         environment => $sdkman::base_env,
         command     => "$sdkman::user_home/.sdkman/bin/sdkman_default_${package_name}_${version}.sh",
         cwd         => $sdkman::user_home,
         user        => $sdkman::owner,
         group       => $sdkman::group,
         path        => '/usr/bin:/usr/sbin:/bin',
         logoutput   => true,
         require     => [Exec["sdk install $package_name $version"],File["$sdkman::user_home/.sdkman/bin/sdkman_default_${package_name}_${version}.sh"]],
         unless      => "test \"$version\" = \$(find $user_home/.sdkman/candidates/$package_name -type l -printf '%p -> %l\\n'| awk '{print \$3}' | awk -F'/' '{print \$NF}')",
         timeout     => $timeout
      }

         exec { "Remove $sdkman::user_home/.sdkman/bin/sdkman_default_${package_name}_${version}.sh":
            command => "rm -f $sdkman::user_home/.sdkman/bin/sdkman_default_${package_name}_${version}.sh",
            cwd     => $sdkman::user_home,
            user    => $sdkman::owner,
            group   => $sdkman::group,
            onlyif  => "test -f $sdkman::user_home/.sdkman/bin/sdkman_default_${package_name}_${version}.sh",
            path    => '/usr/bin:/usr/sbin:/bin',
            provider    => shell,
         }
   }
}

require 5;

use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'         => 'Set::Bag',
	      'VERSION_FROM' => 'Bag.pm',
	      'dist'         => { 'COMPRESS' => 'gzip' },
	      );

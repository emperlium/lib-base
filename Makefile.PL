use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Nick::StandardBase',
    VERSION_FROM    => 'lib/Nick/StandardBase.pm',
    PREREQ_PM       => {
        'Error'             => 0,
        'Class::Singleton'  => 0
    },
    TEST_REQUIRES   => {
        'Test::More' => 0
    }
);

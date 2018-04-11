const String host = 'localsocialnetwork.herokuapp.com';

class AppPreferences {
    AppPreferences._internal();

    static String get phoneNumber => 'phoneNumber';
    static String get password => 'password';
}

class AppRoutes {
    AppRoutes._internal();

    static String get contacts => '/contacts';
    static String get signIn => '/sign-in';
    static String get account => '/account';
}

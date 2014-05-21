dart_runtime_tute_samples
=========================

Code samples for a Dart tutorial.

Setting up the example files (as opposed to setting up the runtime environment).

* The main Dart source file must be named `server.dart`.

* Set up these sample files
    `server.dart` (has hello_world.dart in it)
    `app.yaml`
    `pubspec.yaml` (with all libraries needed for every step)

* run `pub get`

* Files in order of tutorial steps:

* `hello_world.dart`, just displays "Hello, World!"

* `greet_user.dart`, (users package) allows user to log in, displays a greeting to the current user

* `echo_from_form.dart`, (uses a form) lets user sign the guest book using a form, echoes what the user entered.

* `db_sample_no_logging.dart`, (datastore) complete guest book application

* `db_sample_with_logging.dart`, (logging) add extra code for logging. (same as `db_sample_orig.dart`)

* `db_sample_final.dart`, serve static files directly to the browser (stylesheets) XX: works with minimal non-dart changes. Can't get Dart to serve the file as text/css, it keeps coming up text/html.

* `server.dart`, final version, same as `db_sample_final.dart`

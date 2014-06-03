dart_runtime_tute_samples
=========================

Code samples for a Dart tutorial.

Setting up the example files (as opposed to setting up the runtime environment).

Set up:
-------

* The main Dart source file must be named `server.dart`.

* Set up these sample files at the outset
  - `server.dart` (changes in every step)
  - `app.yaml` (changes in some steps)
  - `pubspec.yaml`  (changes in some steps, run pub get after adding dependencies)

* run `pub get`

* fileprogression - contains the progression of the app.yaml and pubspec.yaml files

Files in order of tutorial steps:
---------------------------------

* `1_hello_world.dart`, just displays "Hello, World!"

* `2_greet_user.dart`, (users package) allows user to log in, displays a greeting to the current user

* `3_echo_from_form.dart`, (uses a form) lets user sign the guest book using a form, echoes what the user entered.

* `4_db_sample_no_logging.dart`, (datastore) complete guest book application

* `5_db_sample_with_style.dart`, (forms) adds CSS styles, using static loading (wish it were dynamic
* 
* `6_db_sample_with_logging.dart`, (logging) add extra code for logging. (same as `db_sample_orig.dart`)

* `db_sample_orig.dart`, original file given to me by Søren.

* `server.dart`, the file that is run by dev_appserver, make all changes to this file to run the program as you iterate through the steps

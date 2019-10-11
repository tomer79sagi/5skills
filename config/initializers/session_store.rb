# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_TestDB1_session',
  :secret      => '938213ef377bb4630e7667b051d86e52ed06cf126089226db975006a3c9c98630aab325a428e4fcf0cef62c16478a7d285b25a4be57a79ca65e0cabdc6726e62'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

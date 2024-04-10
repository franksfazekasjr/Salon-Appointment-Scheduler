#!/bin/bash

# Somewhat akin to global variables - set up anything we will need to use
# throughout the script...this variable to query the DB will make things a 
# lot easier to read throughout the script.
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# Print a header/greeting
echo -e "\n ~~~~~ Welcome to My Salon ~~~~~\n"

# Display the menu of services...What service would you like?

MAIN_MENU() {
  # The main menu function should:
  # 1) Get the list of services from the DB
  # 2) Display the list of services formatted as specified
  # 3) Ask the user to select a service
  # 4) Validate the input
  # 5) Pass the validated input to the MAKE_APPOINTMENT function

  # First check if we were passed an argument to the function.
  # This would be a message intended to be displayed above the menu.
  if [[ $1 ]]
  then
    echo -e "\n$1\n"
  fi

  # Now proceed to display the menu.
  echo "Welcome to My Salon.  What service would you like?"

  # Query the DB to get a list of services, format them as specified.
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  # Get input from the user.
  read SERVICE_ID_SELECTED

  # Personally, I would perform other validations
  # but it seems they just want you to hit the DB 
  # with whatever input the user entered and see
  # if you get a result or not.
  SERVICE_NAME_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id = '$SERVICE_ID_SELECTED'")

  # Test the result from the DB.
  while [[ -z $SERVICE_NAME_SELECTED ]] 
  do
    echo -e "\nI couldn't find that service.  What would you like to have done today?"
    echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
    do
      echo "$SERVICE_ID) $SERVICE_NAME"
    done
    read SERVICE_ID_SELECTED
    SERVICE_NAME_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id = '$SERVICE_ID_SELECTED'")

  done

  # Now that we have figured out the service...is the customer new or returning?
  echo -e "\nWhat is your phone number?"
  read CUSTOMER_PHONE

  # There should be validation for the phone number format something like:
  # [[ ! $CUSTOMER_PHONE =~ ^[0-9]{3}-[0-9]{3}-[0-9]{4} ]] 

  # check if the customer exists.
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  if [[ -z $CUSTOMER_ID ]] 
  then
    # Customer Does Not Exist, get their name so we can insert them in the DB.
    echo -e "\nWhat is your name?"
    read CUSTOMER_NAME

    # Just about anything can be a name these days so I'm not going to 
    # do much validation on the entered name.  As long as it exists, INSERT it...
    while [[ -z $CUSTOMER_NAME ]]
    do
      echo -e "\nI did not understand that.  What is your name?"
      read CUSTOMER_NAME
    done

    # We have name and phone, INSERT it.
    INSERT_RESULT=$($PSQL "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")

    # Get the new customer_id
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  fi # Did the customer exist

  # OK we have a valid customer in the DB and have their customer_id so let's get their name.
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = '$CUSTOMER_ID'")

  # OK before we ask about the SERVICE_TIME we need to d osome formatting on the 
  # SERVICE_NAME_SELECTED and CUSTOMER_NAME.  For some reason anything retrieved from
  # the DB has a leading space that we need removed.  Additionally, in a sentance, 
  # we'd like the name of the service to be all lower case. So we will do...
  SERVICE_NAME_SELECTED=$(echo ${SERVICE_NAME_SELECTED,,} | sed -E 's/^ //')
  CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed -E 's/^ //')

  echo -e "\nWhat time would you like your $SERVICE_NAME_SELECTED, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # I'd like to do some fancy regex pattern matching against the time...like 
  # [[ ! $SERVICE_TIME =~ ^[0-9]{1,2}:[0-9]{2}$|^[0-9]{1,2}(am|pm|AM|PM)$ ]]
  # However, for this project, we will be satisfied if they make some type of entry.

  while [[ -z $SERVICE_TIME ]]
  do
    echo -e "\n I'm sorry, I didn't understand that.  What time would you like your $SERVICE_NAME_SELECTED, $CUSTOMER_NAME?"
    read SERVICE_TIME
  done

  # Finally put it all together and insert the appointment.
  INSERT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
  if [[ $INSERT_RESULT == "INSERT 0 1" ]] 
  then
    # Print success message.
    echo -e "\nI have put you down for a $SERVICE_NAME_SELECTED at $SERVICE_TIME, $CUSTOMER_NAME."
  else
    # Print error message.
    echo -e "\nI'm sorry a database error occurred and I can't make your appointment, $CUSTOMER_NAME.  Please try again."

  fi


} # MAIN_MENU

EXIT() {
  echo -e "\n"
}

MAIN_MENU

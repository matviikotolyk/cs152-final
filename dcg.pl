% === DCG for Natural Language Parsing of Vehicle Access Queries ===

% Top-level: full structured query with variations
query(vehicle_query(Type, FuelType, Year, IncomeLevel, Postcode, Zone)) -->
    query_start,
    year(Year),
    optional_income(IncomeLevel),
    fuel(FuelType),
    vehicle_type(Type),
    optional_location(Postcode),
    query_end(Zone).

% Query parts
query_start --> [can], [my].
query_end(Zone) --> [enter], zone(Zone).

% Optional income level - defaults to medium if not specified
optional_income(IncomeLevel) -->
    income(IncomeLevel), !.
optional_income(medium) --> [].

% Optional location - defaults to zone's postcode if not specified
optional_location(Postcode) -->
    [from], postcode(Postcode), !.
optional_location(Postcode) -->
    postcode(Postcode), !.
optional_location(unknown) --> [].

% Components
year(Year) --> 
    [YearAtom], 
    { atom_codes(YearAtom, Codes),
      number_codes(Year, Codes),
      integer(Year),
      Year > 1900,
      Year < 2100
    }.

% Fuel types with variations
fuel(FuelType) --> specific_fuel(FuelType).

specific_fuel(diesel) --> [diesel].
specific_fuel(petrol) --> [petrol]; [gas]; [gasoline].
specific_fuel(electric) --> [electric]; [ev].
specific_fuel(hybrid) --> [hybrid].

% Vehicle types with variations
vehicle_type(Type) --> specific_vehicle(Type).

specific_vehicle(van) --> [van]; [truck]; [lorry].
specific_vehicle(taxi) --> [taxi]; [cab].
specific_vehicle(sedan) --> [sedan]; [car]; [vehicle].

% Income levels
income(low) --> [low], [income].
income(medium) --> [medium], [income]; [average], [income].
income(high) --> [high], [income].

% Postcode and zone (case insensitive)
postcode(Postcode) --> [Postcode], { atom(Postcode) }.
zone(Zone) --> [Zone], { atom(Zone) }.

% Debug predicate for development
debug_tokens(Tokens) :-
    write('DEBUG: Could not parse: '),
    write(Tokens),
    nl.

% Graceful fallback with error reporting
query(unrecognized) --> 
    { debug_tokens(_) },
    [_], !.

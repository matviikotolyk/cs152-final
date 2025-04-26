% === Knowledge Base for LEZ Access Expert System ===
% This system is called via Python subprocess for reliability.
% It works with the following steps:
% 1. Python sends tokenized queries
% 2. DCG rules parse the natural language input
% 3. KB evaluates the rules and returns formatted output
% 4. Python captures and displays the results

:- [dcg].

% === Vehicle Facts ===
:- dynamic vehicle/6.
% vehicle(ID, Type, FuelType, YearOfManufacture, OwnerIncomeLevel, OwnerOutwardPostcode)
% Dynamic predicate allows temporary facts for query evaluation

vehicle(van_1001, van, diesel, 2010, low, e15).
vehicle(taxi_1023, taxi, petrol, 2008, medium, sw1a).
vehicle(sedan_2405, sedan, electric, 2022, medium, e1).
vehicle(sedan_1587, sedan, diesel, 2015, low, cr4).
vehicle(van_3342, van, diesel, 2005, low, se5).
vehicle(taxi_4507, taxi, hybrid, 2018, high, nw3).
vehicle(sedan_9981, sedan, petrol, 2012, medium, br6).
vehicle(van_6705, van, electric, 2021, low, n15).

% === LEZ Zones Facts ===
% lez_zone(Name, OutwardPostcode, Restrictions)

lez_zone(central_london, sw1a, strict).
lez_zone(east_london, e1, moderate).
lez_zone(south_croydon, cr4, moderate).
lez_zone(peckham, se5, strict).
lez_zone(bromley, br6, light).
lez_zone(tottenham, n15, moderate).

% === Policy Thresholds ===
% threshold(EmissionStandard, MaxYear)

threshold(diesel, 2015).
threshold(petrol, 2006).

% === Area Pollution Levels ===
% Areas with already high pollution levels
% Redirecting vehicles from these areas would only concentrate pollution there
% high_pollution_area(OutwardPostcode)

high_pollution_area(e15).  % Stratford - industrial area
high_pollution_area(se5).  % Camberwell - high traffic density
high_pollution_area(cr4).  % Mitcham - industrial zone
high_pollution_area(n15).  % South Tottenham - congested area

% === Exemption and Permit Rules ===

% Vehicles that are electric or hybrid are always allowed
allowed(VehicleID) :-
    vehicle(VehicleID, _, electric, _, _, _).

allowed(VehicleID) :-
    vehicle(VehicleID, _, hybrid, _, _, _).

% Diesel and petrol vehicles must meet year standards unless exempted
restricted_due_to_emission(VehicleID) :-
    vehicle(VehicleID, _, diesel, Year, _, _),
    threshold(diesel, MaxYear),
    Year < MaxYear.

restricted_due_to_emission(VehicleID) :-
    vehicle(VehicleID, _, petrol, Year, _, _),
    threshold(petrol, MaxYear),
    Year < MaxYear.

% Pollution Distribution Permits
% Vehicles from high pollution areas may be allowed to enter LEZ
% to prevent pollution concentration in already affected areas
eligible_for_distribution_permit(VehicleID) :-
    vehicle(VehicleID, _, FuelType, Year, _, Postcode),
    (FuelType = diesel; FuelType = petrol),
    high_pollution_area(Postcode),
    restricted_due_to_emission(VehicleID).

% Main rule: Can a vehicle enter a given LEZ?
can_enter(VehicleID, Zone) :-
    allowed(VehicleID).

can_enter(VehicleID, Zone) :-
    eligible_for_distribution_permit(VehicleID).

% Catch restriction
cannot_enter(VehicleID, Zone) :-
    \+ can_enter(VehicleID, Zone).

% Explanation helper
explain_restriction(VehicleID, Reason) :-
    restricted_due_to_emission(VehicleID),
    vehicle(VehicleID, _, _, _, _, Postcode),
    \+ high_pollution_area(Postcode),
    Reason = 'Vehicle does not meet emission standards and is from a low pollution area. Consider using LEZ in your area.'.

explain_restriction(VehicleID, Reason) :-
    vehicle(VehicleID, _, FuelType, _, _, _),
    (FuelType = diesel; FuelType = petrol),
    Reason = 'Fuel type restricted in the LEZ.'.

% === Process Query and Output ===
% These predicates handle the Python-Prolog interface
% They ensure proper output formatting and error handling
% for the subprocess communication

process_query(vehicle_query(Type, FuelType, Year, IncomeLevel, Postcode, Zone)) :-
    TempID = user_vehicle,
    (retractall(vehicle(TempID, _, _, _, _, _)) ; true),
    % Handle unknown postcode by using the zone's postcode
    (Postcode = 'unknown' -> 
        (lez_zone(Zone, ZonePostcode, _) -> 
            assertz(vehicle(TempID, Type, FuelType, Year, IncomeLevel, ZonePostcode))
        ;   
            assertz(vehicle(TempID, Type, FuelType, Year, IncomeLevel, 'unknown'))
        )
    ;   
        assertz(vehicle(TempID, Type, FuelType, Year, IncomeLevel, Postcode))
    ),
    (can_enter(TempID, Zone) ->
        write('ALLOWED: Vehicle meets all requirements for zone entry.'),
        nl
    ;   
        write('DENIED: '),
        (explain_restriction(TempID, Reason) ->
            write(Reason)
        ;   
            write('Vehicle does not meet zone requirements.')
        ),
        nl
    ).

process_tokens(Tokens) :-
    catch(
        (phrase(query(Q), Tokens) ->
            process_query(Q)
        ;   
            write('ERROR: Could not understand the query format.'),
            nl
        ),
        Error,
        (write('ERROR: '), write(Error), nl)
    ),
    flush_output.

% Main entry point - used for initialization testing
:- initialization(main, main).

main :-
    % This is just for initialization, actual queries will be handled by process_tokens
    true.


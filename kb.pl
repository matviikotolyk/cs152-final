% === Vehicle Facts ===
% vehicle(ID, Type, FuelType, YearOfManufacture, OwnerIncomeLevel, OwnerOutwardPostcode)

vehicle(van_1001, van, diesel, 2010, low, 'E15').
vehicle(taxi_1023, taxi, petrol, 2008, medium, 'SW1A').
vehicle(sedan_2405, sedan, electric, 2022, medium, 'E1').
vehicle(sedan_1587, sedan, diesel, 2015, low, 'CR4').
vehicle(van_3342, van, diesel, 2005, low, 'SE5').
vehicle(taxi_4507, taxi, hybrid, 2018, high, 'NW3').
vehicle(sedan_9981, sedan, petrol, 2012, medium, 'BR6').
vehicle(van_6705, van, electric, 2021, low, 'N15').

% === LEZ Zones Facts ===
% lez_zone(Name, OutwardPostcode, Restrictions)

lez_zone(central_london, 'SW1A', strict).
lez_zone(east_london, 'E1', moderate).
lez_zone(south_croydon, 'CR4', moderate).
lez_zone(peckham, 'SE5', strict).
lez_zone(bromley, 'BR6', light).
lez_zone(tottenham, 'N15', moderate).

% === Policy Thresholds ===
% threshold(EmissionStandard, MaxYear)

threshold(diesel, 2015).
threshold(petrol, 2006).

% === Income Thresholds ===
% Defines who qualifies for financial hardship consideration
% (a frequently ignored factor in LEZ regulations)
low_income_threshold(low).

% === Area Facts (simplified based on postal outward codes to account for general areas) ===
% used to check whether the area already has high emission rates to avoid boundary effects
% deprived_area(OutwardPostcode)

deprived_area('E15').
deprived_area('SE5').
deprived_area('CR4').
deprived_area('N15').

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

% Financial Hardship Temporary Permits
% Low income owners in deprived areas may qualify for transition permits
eligible_for_transition_permit(VehicleID) :-
    vehicle(VehicleID, _, FuelType, Year, Income, Postcode),
    (FuelType = diesel; FuelType = petrol),
    low_income_threshold(Income),
    deprived_area(Postcode),
    restricted_due_to_emission(VehicleID).

% Main rule: Can a vehicle enter a given LEZ?
can_enter(VehicleID, Zone) :-
    allowed(VehicleID).

can_enter(VehicleID, Zone) :-
    eligible_for_transition_permit(VehicleID),
    lez_zone(Zone, ZonePostcode, _),
    vehicle(VehicleID, _, _, _, _, VehiclePostcode),
    VehiclePostcode = ZonePostcode.

% Catch restriction
cannot_enter(VehicleID, Zone) :-
    \+ can_enter(VehicleID, Zone).

% Explanation helper
explain_restriction(VehicleID, Reason) :-
    restricted_due_to_emission(VehicleID),
    Reason = 'Vehicle does not meet emission standards.'.

explain_restriction(VehicleID, Reason) :-
    \+ eligible_for_transition_permit(VehicleID),
    Reason = 'Owner does not qualify for financial hardship exemption.'.

explain_restriction(VehicleID, Reason) :-
    vehicle(VehicleID, _, FuelType, _, _, _),
    (FuelType = diesel; FuelType = petrol),
    Reason = 'Fuel type restricted in the LEZ.'.


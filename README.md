# Low Emission Zone (LEZ) Access Expert System

An expert system that helps determine if a vehicle can enter specific London Low Emission Zones based on various factors including vehicle type, age, fuel type, and area of origin.

## Key Features

- Natural language query interface
- Considers vehicle specifications and environmental impact
- Pollution distribution optimization
- Supports multiple vehicle and fuel types
- Comprehensive rule-based decision making

## Requirements

- Python 3.6+
- SWI-Prolog (swipl)

## Installation

1. Ensure SWI-Prolog is installed and available in your PATH
2. Clone this repository
3. No additional Python packages required

## Usage

Start the application:
```bash
python3 main.py
```

### Example Queries

The system accepts natural language queries. Here are some examples:

1. Modern electric vehicle:
```
Query: can my 2022 electric car enter sw1a
Result: ALLOWED: Vehicle meets all requirements for zone entry.
```

2. Older diesel vehicle from high pollution area:
```
Query: can my 2010 diesel van from e15 enter sw1a
Result: ALLOWED: Vehicle meets all requirements for zone entry.
```

3. Older diesel vehicle from low pollution area:
```
Query: can my 2010 diesel car from sw1a enter e15
Result: DENIED: Vehicle does not meet emission standards and is from a low pollution area. Consider using LEZ in your area.
```

### Supported Parameters

- **Year**: Any year between 1900-2100
- **Fuel Types**: diesel, petrol, electric, hybrid
- **Vehicle Types**: car, van, taxi (and variations like truck, lorry, cab)
- **Areas**: Various London postcodes (e.g., sw1a, e15, se5)

### Environmental Logic

The system considers:
- Vehicle emission standards based on age and fuel type
- Source area pollution levels to prevent pollution concentration
- Automatic approval for electric and hybrid vehicles

## Project Structure

- `main.py`: Python interface and natural language processing
- `kb.pl`: Prolog knowledge base and rules
- `dcg.pl`: Natural language parsing grammar

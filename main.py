import subprocess
import re
from pathlib import Path

# We use subprocess instead of pyswip because:
# 1. More reliable with complex path handling (esp. with spaces)
# 2. Better isolation between Python and Prolog processes
# 3. Cleaner error handling for syntax issues
# 4. Easier deployment since no compilation needed

class PrologError(Exception):
    """Custom exception for Prolog-related errors"""
    pass

def verify_prolog_setup():
    """Verify that SWI-Prolog is installed and the knowledge base is accessible"""
    try:
        # Check if swipl is available
        result = subprocess.run(["swipl", "--version"], capture_output=True, text=True, check=True)
        print(f"✓ Found SWI-Prolog: {result.stdout.split()[0]}")
        
        # Check if required files exist
        kb_path = Path(__file__).parent / "kb.pl"
        dcg_path = Path(__file__).parent / "dcg.pl"
        
        if not kb_path.exists():
            raise PrologError(f"Knowledge base not found at {kb_path}")
        print("✓ Found kb.pl")
        
        if not dcg_path.exists():
            raise PrologError(f"DCG rules not found at {dcg_path}")
        print("✓ Found dcg.pl")
            
        # Test loading both files
        result = consult_and_query("true", test_mode=True)
        if "ERROR" in result:
            raise PrologError(f"Failed to load Prolog files: {result}")
        print("✓ Successfully loaded Prolog files")
            
    except subprocess.CalledProcessError:
        raise PrologError("SWI-Prolog is not installed or not in PATH")
    except Exception as e:
        raise PrologError(f"Setup verification failed: {str(e)}")

def consult_and_query(query, test_mode=False):
    """Send a query to SWI-Prolog and get the result.
    Uses subprocess to ensure clean process isolation and proper UTF-8 handling."""
    kb_path = Path(__file__).parent / "kb.pl"
    dcg_path = Path(__file__).parent / "dcg.pl"
    kb_path_str = str(kb_path).replace("\\", "/")  # Normalize path separators
    dcg_path_str = str(dcg_path).replace("\\", "/")  # Normalize path separators
    
    # Construct the Prolog command
    cmd = ["swipl", "-q"]
    if test_mode:
        cmd.extend(["-t", f"(consult('{kb_path_str}'), consult('{dcg_path_str}'), write('TEST OK'), nl, halt)"])
    else:
        cmd.extend(["-t", f"(consult('{kb_path_str}'), consult('{dcg_path_str}'), {query}, halt)"])
    
    try:
        process = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False  # Don't raise on non-zero exit codes
        )
        
        if process.returncode != 0:
            if process.stderr:
                return f"ERROR: {process.stderr.strip()}"
            return f"ERROR: Process failed with return code {process.returncode}"
            
        return process.stdout.strip()
        
    except Exception as e:
        return f"ERROR: {str(e)}"

def tokenize_input(user_input):
    """Tokenize and normalize user input.
    Converts natural language to tokens that match DCG grammar rules."""
    # Convert to lowercase and remove punctuation
    user_input = user_input.lower()
    user_input = re.sub(r'[?,.]', '', user_input)
    return user_input.split()

def build_query_from_tokens(tokens):
    """Convert tokens to a Prolog query.
    Handles special cases like numbers and escaping quotes."""
    # Escape single quotes in tokens and format them
    formatted_tokens = []
    for token in tokens:
        if token.isdigit():
            # Convert numeric strings to atoms for Prolog
            formatted_tokens.append(f"'{token}'")
        else:
            # Escape any single quotes in the token
            escaped_token = token.replace("'", "''")
            formatted_tokens.append(f"'{escaped_token}'")
    
    query_list = "[" + ",".join(formatted_tokens) + "]"
    return f"process_tokens({query_list})"

def main():
    """Provides a natural language interface to the Prolog expert system."""
    print("\n🚗 LEZ Access Checker")
    print("Type your vehicle details to check if you can enter a low-emission zone.")
    print("Example: can my 2010 low income diesel van from e15 enter sw1a\n")
    
    try:
        verify_prolog_setup()
    except PrologError as e:
        print(f"⚠️  Setup Error: {str(e)}")
        print("Please ensure SWI-Prolog is installed and in your system PATH")
        return

    while True:
        try:
            user_input = input("📝 Your query (or type 'exit'): ").strip()
            if not user_input:
                continue
                
            if user_input.lower() == 'exit':
                print("👋 Goodbye!")
                break

            tokens = tokenize_input(user_input)
            if not tokens:
                print("⚠️  Please enter a valid query")
                continue

            prolog_query = build_query_from_tokens(tokens)
            result = consult_and_query(prolog_query)
            
            if result.startswith('ERROR:'):
                print(f"⚠️  {result}")
            else:
                print(f"{result}\n")

        except PrologError as e:
            print(f"⚠️  {str(e)}")
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break
        except Exception as e:
            print(f"⚠️  An unexpected error occurred: {str(e)}")

if __name__ == "__main__":
    main()

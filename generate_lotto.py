"""Generate random numbers for lotteries."""


import random
import sys

COLORS = {
    "red": "\033[1;31;49m",
    "green": "\033[1;32;49m",
    "yellow": "\033[1;33;49m",
    "blue": "\033[1;34;49m",
    "purple": "\033[1;35;49m",
    "cyan": "\033[1;36;49m",
    "white": "\033[1;37;49m",
    "black": "\033[1;30;49m",
    "reset": "\033[0;0m",
}


GAME_CONFIGS = {
    "Mega Millions": {
        "range": (1, 71),
        "picks": 5,
        "extra": (1, 26),
        "extra_name": "mega ball",
        "color": "green",
        "extra_color": "red",
    },
    "Powerball": {
        "range": (1, 70),
        "picks": 5,
        "extra": (1, 27),
        "extra_name": "powerball",
        "color": "green",
        "extra_color": "red",
    },
    "Cash 5": {
        "range": (1, 42),
        "picks": 5,
        "color": "green",
    },
    "Lucky for Life": {
        "range": (1, 49),
        "picks": 5,
        "extra": (1, 19),
        "extra_name": "lucky ball",
        "color": "green",
        "extra_color": "red",
    },
    "Pick 4": {
        "range": (1, 10),
        "picks": 4,
        "color": "green",
    },
    "Pick 3": {
        "range": (1, 10),
        "picks": 3,
        "color": "green",
    },
}


def print_menu() -> None:
    """Print the menu."""
    for idx, game in enumerate(GAME_CONFIGS, 1):
        print(f"{idx}) Play {game}")
    print("0) Exit")


def get_ticket_numbers(game_config: dict) -> str:
    """Generate ticket numbers based on game configuration."""
    picks = random.sample(range(*game_config["range"]), game_config["picks"])
    result = f"{COLORS[game_config['color']]}{' '.join(map(str, picks))}{COLORS['reset']}"

    if "extra" in game_config:
        extra_pick = random.choice(range(*game_config["extra"]))
        result += f" {COLORS[game_config['extra_color']]}{extra_pick}{COLORS['reset']}"

    return result


def play_game(game_name: str) -> None:
    """Play the specified game."""
    how_many = int(input(f"How many {game_name} tickets would you like? "))
    print(f"\nYour {game_name} numbers are:")

    for _ in range(how_many):
        print(get_ticket_numbers(GAME_CONFIGS[game_name]))
    print()


def main() -> None:
    """Main function."""
    while True:
        print_menu()
        try:
            option = int(input("Enter your choice: "))
            if 1 <= option <= len(GAME_CONFIGS):
                game_name = list(GAME_CONFIGS.keys())[option - 1]
                play_game(game_name)
            elif option == 0:
                sys.exit()
            else:
                print(f"\nInvalid option. Please enter a number between 1 and {len(GAME_CONFIGS)}.\n")
        except ValueError:
            print("\nWrong input. Please enter a number ...\n")


if __name__ == "__main__":
    main()

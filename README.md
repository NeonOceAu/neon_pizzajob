![GitHub all releases](https://img.shields.io/github/downloads/NeonOceAu/neon_pizzajob/total?color=blue&style=flat-square)

# neon_pizzajob

A FiveM job script for a pizza delivery role, seamlessly integrated with Ox Lib and compatible with both ESX and QBCore frameworks. Players can take on the role of a pizza delivery driver, continuously delivering pizzas across the city until they choose to stop.

## Features

- **Ox Lib Integration**: Smooth progress bars and notifications to enhance user experience.
- **Continuous Delivery System**: Players can keep delivering pizzas to random locations around the city without interruption, only stopping when they choose.
- **Customizable Config**: Set pay ranges, delivery locations, job titles, and more through an easy-to-edit config file.
- **Framework Compatibility**: Supports both ESX and QBCore frameworks for broad server compatibility.
- **Unique Delivery Vehicles**: Each player receives a vehicle with a unique plate to prevent overlap, allowing multiple players to deliver at once without issues.
- **Anti-Exploit Protection**: Events are secured to prevent exploitation, ensuring fair gameplay.
- **Leaderboard**: View a leaderboard of the top pizza deliverers, adding a competitive edge to the job.
- **Optimized Performance**: Lightweight and designed to minimize resource usage for smooth server performance.
- **User-Friendly Interface**: Easy-to-use menus and intuitive navigation for players.

## Installation

1. **Download and extract** the `neon_pizzajob` script into your server’s resources folder.
   
2. **Add the script to your server’s resource start list** in `server.cfg`:
   ```plaintext
   ensure neon_pizzajob
   ```

3. **Import the SQL Table**:
   - Run the following SQL commands in your database to create the necessary table:
     ```sql
     CREATE TABLE IF NOT EXISTS `neon_pizzajob` (
         `id` INT AUTO_INCREMENT PRIMARY KEY,
         `citizenid` VARCHAR(50) NOT NULL,
         `total_deliveries` INT DEFAULT 0
     );
     ```

4. **Configure the Script**:
   - Open the `config.lua` file to adjust settings like `Config.Pay`, delivery locations, target settings, and more.
   - Set `Config.Target` to either `'ox_target'`, `'qb-target'`, or `'none'` depending on your preferred targeting system.

5. **Dependencies**:
   - Ensure Ox Lib is installed on your server, as this script utilizes its features for progress bars and notifications.
   - For QBCore or ESX compatibility, make sure the respective framework is correctly set up.

## Support

If you encounter any issues or need assistance, please join our discord @ discord.gg/neonscripts

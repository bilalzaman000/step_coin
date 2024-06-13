import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Theme/ThemeProvider.dart';
import '../login/login.dart';
import 'Account/ChangePassword.dart';
import 'Account/EditProfile.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    Color appBarColor = themeProvider.getTheme().brightness == Brightness.light ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Account'),
        backgroundColor: appBarColor,
      ),
      body: ListView(
        children: [
          _buildListItem(
            context,
            'Edit Profile',
            Icons.person,
            Icons.arrow_forward_ios,
            EditProfileScreen(),
            themeProvider,
          ),
          _buildListItem(
            context,
            'Change Password',
            Icons.lock,
            Icons.arrow_forward_ios,
            ChangePasswordScreen(),
            themeProvider,
          ),
          _buildListItemWithToggle(
            context,
            'Dark Theme',
            Icons.nightlight_round,
            themeProvider,
          ),
          _buildLogoutItem(context, themeProvider),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String title, IconData leadingIcon, IconData trailingIcon, Widget nextScreen, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    Color cardColor = theme.brightness == Brightness.light ? Color(0xFFFAFAFB) : theme.colorScheme.surface;

    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeProvider.getTheme().brightness == Brightness.dark ? Colors.black : Colors.white,
          child: Icon(leadingIcon, color: themeProvider.getTheme().brightness == Brightness.dark ? Colors.white : Colors.black),
          radius: 24,
        ),
        title: Text(
          title,
          style: TextStyle(color: themeProvider.getTheme().brightness == Brightness.dark ? Colors.white : Colors.black),
        ),
        trailing: Icon(trailingIcon, color: theme.iconTheme.color),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        },
      ),
    );
  }

  Widget _buildListItemWithToggle(BuildContext context, String title, IconData leadingIcon, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    Color cardColor = theme.brightness == Brightness.light ? Color(0xFFFAFAFB) : theme.colorScheme.surface;

    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeProvider.getTheme().brightness == Brightness.dark ? Colors.black : Colors.white,
          child: Icon(leadingIcon, color: themeProvider.getTheme().brightness == Brightness.dark ? Colors.white : Colors.black),
          radius: 24,
        ),
        title: Text(
          title,
          style: TextStyle(color: themeProvider.getTheme().brightness == Brightness.dark ? Colors.white : Colors.black),
        ),
        trailing: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Switch(
              value: themeProvider.getTheme() == darkTheme,
              onChanged: (value) {
                if (value) {
                  themeProvider.setTheme(darkTheme);
                } else {
                  themeProvider.setTheme(lightTheme);
                }
              },
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.black,
              activeColor: Colors.black,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    Color cardColor = theme.brightness == Brightness.light ? Color(0xFFFAFAFB) : theme.colorScheme.surface;

    return Card(
      color: cardColor,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeProvider.getTheme().brightness == Brightness.dark ? Colors.black : Colors.white,
          child: Icon(Icons.logout, color: themeProvider.getTheme().brightness == Brightness.dark ? Colors.white : Colors.black),
          radius: 24,
        ),
        title: Text(
          'Logout',
          style: TextStyle(color: themeProvider.getTheme().brightness == Brightness.dark ? Colors.white : Colors.black),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
        },
      ),
    );
  }
}

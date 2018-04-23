import React, { Component } from 'react';

import {
  Platform,
  StyleSheet,
  Text,
  Image,
  View,
  TouchableOpacity
} from 'react-native';

export default class MainScreen extends Component {

  render() { 
    return (
      <View style={styles.container}>
        <Text style={styles.normalText}>MainScreen</Text>
      </View>
    ); 
  } 
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  normalText: {
    color: '#000',
    fontSize: 25,
  }
});


/*
*   Program:
*     analyzer.cpp
*
*   Author:
*     Carlos Moreno
*
*   Description:
*     This program will analyze the given log file that contains
*     values for samples received in packets. These packets are
*     possibly dropped, in which case, the value for the sample
*     is estimated using linear interpolation. The data from the
*     log file is parsed and filled into vectors. These are then
*     used to calculate the total average DQI. The DQI calculation
*     has 3 different methods for the denominator: actual value,
*     global range, and local range.
*
*   Input:
*     argv[1] - the log filename to analyze
*     The assumed format for the log file is:
*       <blank line>
*       Index   Rcvd    Predict   Expect
*       --------------------------------
*       <int>   <int>   <int>     <int>
*
*   Output:
*     The total average DQI for 3 different calculation methods.
*     This is displayed to console.
*
*   Usage:
*     g++ -o analyzer -std=c++11 analyzer.cpp
*     ./analyzer xxx
*/

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <cmath>
#include <climits>

using namespace std;

// Simple auxiliary function that checks if i
// is a member of the vector v.
inline bool member(vector<int>& v, int i) {
  for (int j = 0; j < v.size(); j++) {
    if (v[j] == i) {
      return true;
    }
  }
  
  return false;
}

int main(int argc, char** argv) {
  ifstream      ifs;
  string        s;
  vector<int>   act, est, maxes, mins;
  float         f, dqi, p, sum;
  unsigned int  i, j;
  int           min, max, range;
  
  // Parse the log file and populate the vectors
  ifs.open(argv[1]);
  getline(ifs, s);
  getline(ifs, s);
  getline(ifs, s);
  while (getline(ifs, s)) {
    if (s[0] == 'P') {
      break;
    }
    
    stringstream ss(s);
    
    ss >> f >> f >> f;
    est.push_back(f);
    
    ss >> f;
    act.push_back(f);
  }
  ifs.close();
  
  // Calculate the total average DQI using actual value method
  sum = 0.f;
  for (i = 0; i < act.size(); i++) {
    dqi  = abs(est[i] - act[i]) / static_cast<float> (act[i]);
    p    = 1.f - dqi;
    sum += p;
  }
  sum /= static_cast<float> (act.size());
  cout << "Total average DQI using actual value method: " << sum << endl;
  
  // Calculate the total average DQI using global range method
  min = INT_MAX;
  max = INT_MIN;
  for (i = 0; i < act.size(); i++) {
    min = (min < act[i]) ? min : act[i];
    max = (max > act[i]) ? max : act[i];
  }
  range = max - min;
  sum   = 0.f;
  for (i = 0; i < act.size(); i++) {
    dqi  = abs(est[i] - act[i]) / static_cast<float> (range);
    p    = 1.f - dqi;
    sum += p;
  }
  sum /= static_cast<float> (act.size());
  cout << "Total average DQI using global range method: " << sum << endl;
  
  // Calculate the total average DQI using local range method
  for (i = 0; i < act.size(); i++) {
    if (i == 0) {
      if (act[i + 1] < act[i]) {
        maxes.push_back(i);
      }
      else {
        mins.push_back(i);
      }
    }
    else if (i == act.size() - 1) {
      if (act[i - 1] < act[i]) {
        maxes.push_back(i);
      }
      else {
        mins.push_back(i);
      }
    }
    else {
      if (act[i - 1] < act[i] && act[i + 1] < act[i]) {
        maxes.push_back(i);
      }
      else if (act[i - 1] > act[i] && act[i + 1] > act[i]) {
        mins.push_back(i);
      }
    }
  }
  sum = 0.f;
  for (i = 0; i < act.size(); i++) {
    if (member(maxes, i)) {
      max = act[i];
      
      for (j = 0; j < mins.size(); j++) {
        if (j == 0 && mins[j] > i) {
          min = act[mins[0]];
          break;
        }
        else if (j == mins.size() - 1) {
          min = act[mins[j]];
          break;
        }
        else if (mins[j] < i && mins[j + 1] > i) {
          min = act[mins[j]];
          break;
        }
      }
    }
    else if (member(mins, i)) {
      min = act[i];
      
      for (j = 0; j < maxes.size(); j++) {
        if (j == 0 && maxes[j] > i) {
          max = act[maxes[0]];
          break;
        }
        else if (j == maxes.size() - 1) {
          max = act[maxes[j]];
          break;
        }
        else if (maxes[j] < i && maxes[j + 1] > i) {
          max = act[maxes[j]];
          break;
        }
      }
    }
    else {
      for (j = 0; j < maxes.size(); j++) {
        if (j == 0 && maxes[j] > i) {
          max = act[maxes[0]];
          break;
        }
        else if (j == maxes.size() - 1) {
          max = act[maxes[j]];
          break;
        }
        else if (act[i - 1] > act[i] && maxes[j] < i && maxes[j + 1] > i) {
          max = act[maxes[j]];
          break;
        }
        else if (act[i - 1] < act[i] && maxes[j] > i) {
          max = act[maxes[j]];
          break;
        }
      }
      
      for (j = 0; j < mins.size(); j++) {
        if (j == 0 && mins[j] > i) {
          min = act[mins[0]];
          break;
        }
        else if (j == mins.size() - 1) {
          min = act[mins[j]];
          break;
        }
        else if (act[i - 1] < act[i] && mins[j] < i && mins[j + 1] > i) {
          min = act[mins[j]];
          break;
        }
        else if (act[i - 1] > act[i] && mins[j] > i) {
          min = act[mins[j]];
          break;
        }
      }
    }
    
    range = max - min;
    dqi   = abs(est[i] - act[i]) / static_cast<float> (range);
    p     = 1.f - dqi;
    sum  += p;
  }
  sum /= static_cast<float> (act.size());
  cout << "Total average DQI using local range method: " << sum << endl;
  
  return 0;
}
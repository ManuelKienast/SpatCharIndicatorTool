# SpatCharIndicatorTool

Introduction

The SpatCharIndicatorTool is a combination of R-scripts and functions sending wrapped SQL queries to a PostGis-database. The queries are calculating spatial indicators such as densities of objects over a selected aggregation area or calculating the entropy, i.e. the diverstiy, of objects. Furthermore those indicators are feeeding into an Boosted Regression Tree (BRT) Model for prediction of spatial behavior patterns occurring in the study area.

At the moment it is but a collection of scripts and functions with the goal of finally incorporating them into one clean and tidy superscript facilitating a userfreindly workflow while the calclulations are running unnoticed in the background.

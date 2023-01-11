# Airship Mobile Framework Proxy

The goal of this library is to contain all the common cross platform framework code for React Native, Cordova, Flutter, etc... in order to ease develop as well as make the various modules have a consistent interface.


The framework will manage taking off, setting up listeners, and persisting state.

## Proxy Classes

The proxy classes will have JSON friendly input and outputs. The classes are divided up into sub component proxy classes, that should ideally match what we expose in the framework layer.

## Event Emitter

The event emitter will store any pending events from the SDK, and provide thread safe methods to process events when the plugin is able to receive them.

The event emitter should be setup before the proxy classes are initialized. 



# Policies System
Allows to specify a number of special policies per project. These may be specialised to your individual needs.

## Development Note
This module is still very much work-in-progress. Not functional yet.

## Motivation
Imagine you maintain a legacy windows codebase with heavy use of MFC and no clear separation of Data Layer, Business Logic, Presentation Layer, ..
You want to start splitting your targets apart to enfoce a clean separation of layers.

Problem: Who enforces that we only use MFC in the presentation layer?

Answer:  Custom Policies!

Each target may specify a set of policies (a set of custom variables specific to that target) which may be "ALLOW_USAGE_OF_MFC=OFF", for example, set_target_policies(ALLOW_USAGE_OF_MFC OFF ...).
At the end of your root CMakeLists, you can then generate custom yaml files that include said policies and connect any script to these yaml files which enforces the policies as you see fit.

Note: Policies do not need to be restrictions but can be any information you may want to attach to a project. All the policies do is create yaml files. Since CMake already builds a database-like structure of our projects, why not reuse this system to collect more information?
The goal is simply to create a single source of truth of what a target is, what is can do, and how it must behave - not just how it's built.

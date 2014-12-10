# intro

Holds helper types and providers for puppet helpers for orchestration.

# overview

## types

* consul\_kv - Write arbitrary keys into consul
* consul\_kv\_blocker - Blocks catalog compilation until certain keys exist in consul

* dns\_blocker - Blocks catalog until an A-record is registered
* runtime\_fail - Type that can be used to partial fail a subgraph from the catalog based on compile time data (like missing data)

## functions

* dns\_resolve - performs a forward DNS lookup for a a record, and returns a list of ip addresses
* easy\_host - converts a has of the form hostname => ip into the appropriate /etc/host entries
* service\_discover\_consul - returns a hash of name => ip based on a consul lookup using service name and optional tags
* service\_discover\_dns - performs an SRV record lookup from DNS, returns either a list of hostnames or ip addresses

# SafeStream
A decentralized insurance protocol for streaming income built on Stacks.

## Overview
SafeStream allows users to insure their streaming income (e.g. from content creation, subscriptions etc) by paying regular premiums. If their streaming income drops below a certain threshold, they can claim insurance payouts.

## Features
- Create insurance policies with customizable parameters
- Pay premiums in STX tokens
- File claims when income drops
- Automated claim verification and payouts
- Pool premiums for shared risk
- Policy expiration after 1 year of inactivity

## Contract Interface
### Policy Management
- create-policy
- pay-premium 
- file-claim
- cancel-policy

### Admin Functions
- add-verified-income-source
- update-pool-params

## Policy Rules
- Policies expire after approximately 1 year (5256 blocks) from last premium payment
- Expired policies cannot process claims or accept premium payments
- Premium payments reset the expiration timer

## Testing & Deployment
Instructions for running tests and deploying contracts...

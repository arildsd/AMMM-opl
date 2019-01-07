/*********************************************
 * OPL 12.6.0.0 Model
 * Author: Jørgen
 * Creation Date: 29. okt. 2018 at 14:15:57
 *********************************************/
int nServices=...;
int nBuses=...;
int nDrivers=...;
range S=1..nServices;
range B=1..nBuses;
range D=1..nDrivers;
float time_start[s in S]=...;
int duration_min[s in S]=...;
float duration_km[s in S]=...;
int nPassengers[s in S]=...;
int cap_b[b in B]=...;
float euros_min_b[b in B]=...;
float euros_km_b[b in B]=...;
int maxBuses=...;
int max_d[d in D]=...;
float CBM=...;
float CEM=...;
int BM=...;
int overlapping[s1 in S, s2 in S];

execute {

	// Calculate overlapping services
	for(var i=1;i<=nServices;i++){
		for	(var j=1;j<=nServices;j++){
			var start_overlapping = (time_start[i] + duration_min[i] < time_start[j] + duration_min[j])	&& 
									(time_start[i] + duration_min[i] > time_start[j]); 
			var end_overlapping = (time_start[i] > time_start[j]) && (time_start[i] < time_start[j] + duration_min[j]);
			overlapping[i][j] = start_overlapping || end_overlapping
			
		}
	}
};


dvar boolean x[s in S, d in D]; //Element is true iff the driver d is assigned to the service s
dvar boolean y[s in S, b in B]; //Element is true iff the bus b is assigned to the service s
dvar boolean overtime[d in D]; //Element is true iff the driver d has worked more than BM minutes
dvar boolean assignedBus[b in B]; //Element is true iff bus b is assigned to any service

dvar float+ kmCostBuses;
dvar float+ minuteCostBuses;
dvar float+ baseCostDrivers;
dvar float+ extraCostDrivers;
//dvar float+ costDrivers;
minimize kmCostBuses + minuteCostBuses + baseCostDrivers + extraCostDrivers;


subject to {


//Constraint 1 - Services should be operated with buses with enough capacity
forall (b in B, s in S)
  nPassengers[s] * y[s,b] <= cap_b[b] * y[s,b];

//Constraint 2.a - The same bus cannot serve two services that overlap in time
forall (b in B, s1 in S, s2 in S)
  y[s1, b] + y[s2, b] + overlapping[s1, s2] <= 2;

//Constraint 2.b - The same driver cannot serve two services that overlap in time
forall (d in D, s1 in S, s2 in S)
  x[s1, d] + x[s2, d] + overlapping[s1, s2] <= 2;

//Constraint 3 - We must respect the maximum number of working minutes for each driver
forall(d in D)
  sum(s in S) duration_min[s] * x[s,d] <= max_d[d];
  
//Constraint 4 - Auxiliary constraint to set the assignedBus variable
forall(b in B)
	sum(s in S) y[s,b] <= nServices * assignedBus[b];

//Constraint 5 - We can at most use a total of maxBuses buses
sum(b in B) assignedBus[b] <= maxBuses;

//Constraint 6 - A service can only have one bus assigned
forall(s in S)
  sum(b in B) y[s,b] == 1;

//Constraint 7 - A service can only have one driver assigned
forall(s in S)
  sum(d in D) x[s,d] == 1;


//Constraint 8 - Force the overtime variable to be set
forall(d in D) overtime[d] >= ((sum(s in S) x[s,d] * duration_min[s]) - BM) / max_d[d];

//Constraint 8.a - Overtime variable
forall(d in D) overtime[d] <= 1 + ((sum(s in S) x[s,d] * duration_min[s]) - BM) / max_d[d];

//Constraint 9 - Constraint for setting the cost of buses per km
sum(b in B)
  sum(s in S)
    y[s,b] * duration_km[s]*euros_km_b[b] <= kmCostBuses;
    
//Constraint 10 - Constraint for setting the cost of buses per min
sum(b in B)
  sum(s in S)
    y[s,b] * duration_min[s]*euros_min_b[b] <= minuteCostBuses;

//Constraint 11 - Constraint for setting the base cost of drivers
sum(d in D)
  (sum(s in S) x[s,d] * duration_min[s] * CBM) <= baseCostDrivers;

//Constraint 12 - Constraint for setting the extra cost of drivers
sum(d in D) overtime[d] *
	((sum(s in S) x[s,d] * duration_min[s]) - BM) * (CEM - CBM) <= extraCostDrivers;
}
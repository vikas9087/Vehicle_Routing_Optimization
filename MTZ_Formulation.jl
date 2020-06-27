using JuMP, Gurobi, DataFrames, CSVFiles;
NHG=Model(solver=GurobiSolver(MIPGap=0.10));
N=125;
input_data_file="C:/Users/garg1/Desktop/Revised Solution/file to be used/distance.csv";
Distance=DataFrame(load(input_data_file));
#for i=1:N; for j=1:N;
#    if i==j
#        Distance[i,j]=10000
#    else
#    end
#end
#end
#Distance[1,N]=10000;
#Distance[N,1]=10000;
input_data_file="C:/Users/garg1/Desktop/Revised Solution/file to be used/time.csv";
Time=DataFrame(load(input_data_file));
input_data_file="C:/Users/garg1/Desktop/Revised Solution/file to be used/orders.csv";
Orders=DataFrame(load(input_data_file));
#Calculate the orders for different days
Orders_Mon=Orders[:,3]; #orders_Mon
Orders_Tue=Orders[:,4]; #orders_Tue
Orders_Wed=Orders[:,5]; #orders_Wed
Orders_Thu=Orders[:,6]; #orders_Thu
Orders_Fri=Orders[:,7]; #orders_Fri
Min_ST=30; #Minimum Service time at a Store
Cap_v=3200; #Capacity of the vehicle
Unload_rate=0.03; #unloading rate of the vehicle.
#calculate the service time at each customer
ST_Mon=[max(Min_ST,Unload_rate*Orders_Mon[i]) for i in 1:N]; #orders of Mon
ST_Tue=[max(Min_ST,Unload_rate*Orders_Tue[i]) for i in 1:N]; #orders of Tue
ST_Wed=[max(Min_ST,Unload_rate*Orders_Wed[i]) for i in 1:N]; #orders of Wed
ST_Thu=[max(Min_ST,Unload_rate*Orders_Thu[i]) for i in 1:N]; #orders of Thu
ST_Fri=[max(Min_ST,Unload_rate*Orders_Fri[i]) for i in 1:N]; #orders of Fri
V=5;
Nr_Active=0
for i=1:N;
    if Orders_Mon[i]!=0 #Chnage the orders data
        Nr_Active=Nr_Active+1
    end
end
Active=Array{Int64}(Nr_Active);
dummy=0
for j=1:N;
    if Orders_Mon[j]!=0 #Chnage the orders data
        dummy=dummy+1
        Active[dummy]=j
    end
end
#defining variables
@variable(NHG,x[i=1:N,j=1:N,k=1:V],Bin);
@variable(NHG,u[1:N]>=0);
#defining objective function
@objective(NHG,Min,sum(Distance[Active[i],Active[j]]*x[Active[i],Active[j],k] for i=1:Nr_Active,j=1:Nr_Active,k=1:V));

@constraint(NHG,u[1]==1);       #no difference
for i=2:Nr_Active;
    @constraint(NHG,u[Active[i]]<=Nr_Active)
end
for i=2:Nr_Active;
    @constraint(NHG,2<=u[Active[i]])
end

#Flow Balance at Customer           ###No difference changing this constraint
for j=1:Nr_Active; for k=1:V
    @constraint(NHG,sum(x[Active[i],Active[j],k] for i=1:Nr_Active)-sum(x[Active[j],Active[i],k] for i=1:Nr_Active)==0)
end
end

#Vehicle Capacity constraint            ##No difference changing this constraint
for k=1:V;
    @constraint(NHG,sum(Orders_Mon[Active[i]]*x[Active[i],Active[j],k] for i=1:Nr_Active,j=1:Nr_Active)<=Cap_v) #Chnage the orders data
end

#Total duty hours which must be less than or equal to 14        ###no difference
for k=1:V;       #Chnage the orders data
    @constraint(NHG,(sum(Time[Active[i],Active[j]]*x[Active[i],Active[j],k] for i=1:Nr_Active,j=1:Nr_Active)+sum(ST_Mon[Active[i]]/60*x[Active[i],Active[j],k] for i=1:Nr_Active,j=1:Nr_Active))<=14)
end

#Total driving time should be less than or equal to 11.     ##no difference
for k=1:V;
    @constraint(NHG,sum(x[Active[i],Active[j],k]*Time[Active[i],Active[j]] for i=1:Nr_Active,j=1:Nr_Active)<=11)
end

#All the vehicles must start from DC            ##no difference
for k=1:V;
    @constraint(NHG,sum(x[1,Active[j],k] for j=1:Nr_Active)==1)
end

#All the vehicles must return to DC             ##no differennce
for k=1:V;
    @constraint(NHG,sum(x[Active[j],N,k] for j=1:Nr_Active)==1)
end

#supply demand constraint                       ##solution feasible but supply is not meeting demand
@constraint(NHG,sum(Orders_Mon[Active[j]]*x[Active[i],Active[j],k] for i=1:Nr_Active,j=1:Nr_Active,k=1:V)==sum(Orders_Mon[Active[j]] for j=1:Nr_Active));

# To avoid looping                      ##no difference
for i=1:Nr_Active; for j=1:Nr_Active;
    @constraint(NHG,sum(x[Active[i],Active[j],k] for k=1:V)+sum(x[Active[j],Active[i],k] for k=1:V)<=1)
end
end

#total number of arcs to be followed
@constraint(NHG,sum(x[Active[i],Active[j],k] for i=1:Nr_Active,j=1:Nr_Active,k=1:V)<=Nr_Active-1);
for i=2:Nr_Active; for j=2:Nr_Active; for k=1:V;
    if i!=j
        @constraint(NHG,sum(u[Active[i]]-u[Active[j]]+(Nr_Active-1)x[Active[i],Active[j],k])<=(Nr_Active-1))
    else
    end
end
end
end

#Each customer customer must be visited once
#for j=1:Nr_Active;
#    @constraint(NHG,sum(x[Active[i],Active[j],k] for i=1:Nr_Active,k=1:V)==1)
#end

status=solve(NHG)
println("Objective Value is=",getobjectivevalue(NHG))
value=getvalue(x);
println(sum(Orders_Wed[Active[j]]*value[Active[i],Active[j],k] for i=1:Nr_Active,j=1:Nr_Active,k=1:V)) #Chnage the orders data
for i=1:N; for j=1:N;
        if value[i,j,3]!=0
        println("value[$i,$j,3]=",value[i,j,3])
    else
    end
end
end

for i=1:N; for j=1:N;
        if value[i,j,5]!=0
        println("value[$i,$j,5]=",value[i,j,5])
    else
    end
end
end

for i=1:N; for j=1:N;
        if value[i,j,4]==1
        println("value[$i,$j,4]=",value[i,j,4])
    else
    end
end
end

for i=1:N; for j=1:N;
        if value[i,j,2]==1
        println("value[$i,$j,2]=",value[i,j,2])
    else
    end
end
end

for i=1:N; for j=1:N;
        if value[i,j,1]==1
        println("value[$i,$j,1]=",value[i,j,1])
    else
    end
end
end

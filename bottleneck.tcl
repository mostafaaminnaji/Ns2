#In the nam of GOD
# Communication Networks Final Project
#This code is written by Mostafa Amin-Naji
# For contact: mostafa.amin.naji@gmail.com

##############################################################################
#Part 6 - Find Botleneck Nodes
##############################################################################

#Create a simulator object
set nS [new Simulator]

#Open the NAM trace file
set nf [open out.nam w]
$nS namtrace-all $nf
#Define a 'finish' procedure
proc finish {} {
        global nS nf
        $nS flush-trace
#Close the output files
        #Close the NAM trace file
        close $nf
        #Execute NAM on the trace file
        exec nam out.nam &
        exit 0
}

#s1, s2 and s3 act as sources.
set n0 [$nS node]
set n1 [$nS node]
set n2 [$nS node]
#G acts as a gateway.
set n3 [$nS node]
#r acts as a receiver.
set n4 [$nS node]
$n4 shape box

#Define different colors for dats flows
$nS color 1  red;# the color of packets from s1
$nS color 2 blue ;# the color of packets from s2


#Create links between the needed nodes / FIFO method is equal to DropTail
$nS duplex-link $n0 $n2 1Mb 10ms RED 
# Node 0 to node 2 with BW=1 Mb , Time delay: 10 ms, Buffer_Limitaion= 10
$nS duplex-link $n1 $n2 1Mb 10ms RED
# Node 1 to node 2 with BW=1 Mb , Time delay: 10 ms, Buffer_Limitaion= 10
$nS duplex-link $n2 $n3 2Mb 100ms RED
# Node 2 to node 3 with BW=2 Mb , Time delay: 100 ms, Buffer_Limitaion= 10
$nS duplex-link $n1 $n3 2Mb 1ms RED 
# Node 1 to node 3 with BW=2 Mb , Time delay: 10 ms, Buffer_Limitaion= None
$nS duplex-link $n0 $n3 2Mb 10ms RED
# Node 0 to node 3 with BW=2 Mb , Time delay: 10 ms, Buffer_Limitaion= None
$nS duplex-link $n0 $n1 2Mb 10ms RED
# Node 0 to node 1 with BW=2 Mb , Time delay: 10 ms, Buffer_Limitaion= None



#Bottleneck Link ----  At the First BW was 10Mb and after it, BW is reduced into 1Mb
$nS duplex-link $n3 $n4 1Mb 10ms RED


#Set Queue Size of link to 10 / Buffer limitation
$nS queue-limit $n0 $n2 10
$nS queue-limit $n1 $n2 10
$nS queue-limit $n2 $n3 10



#Setup a TCP connection
set tcp [new Agent/TCP]
$nS attach-agent $n0 $tcp
$tcp set fid_ 1

#Setup a UDP connection
set udp [new Agent/UDP]
$nS attach-agent $n1 $udp
$udp set fid_ 2

# Define a proc that attaches TCP agent to a previously created node
# and attach an expo traffic gen. to the agent 
proc attach-expo-traffic {node sink size burst idle rate} {
#Get an instance of the simulator
set nS [Simulator instance]

#Create a TCP agent and attach to node
set source [new Agent/TCP]
$nS attach-agent $node $source

#Create an expo traffic agent
set traffic [new Application/Traffic/Exponential]
$traffic set packetSize_ $size
$traffic set burst_time_ $burst
$traffic set idle_time_ $idle
$traffic set rate_ $rate


#Attach traffic source to the traffic gen.
$traffic attach-agent $source
#Connect the source and the sink
$nS connect $source $sink
return $traffic
}

#In order to Send packets from n0 and n1 to n4
#Attach Null to n4
set sink0 [new Agent/Null]
$nS attach-agent $n4 $sink0
$nS connect $udp $sink0

set sink1 [new Agent/TCPSink]
$nS attach-agent $n4 $sink1

set source0 [attach-expo-traffic $n0 $sink1 200 2s 1s 100k]


#Setup a CBR over UDP connectio
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1Mb
$cbr set random_ false
$cbr set fid_ 1


#Schedule events for the CBR and Exponential agents
$nS at 0.0 "$n0 label Sender1"
$nS at 0.0 "$n1 label Sender2"
$nS at 0.0 "$n2 label Sender3"
$nS at 0.0 "$n3 label Gateway"
$nS at 0.0 "$n4 label Receiver"


$nS at 0.0 "$cbr start"
$nS at 0.1 "$source0 start"

$nS at 4.5 "$source0 stop"
$nS at 4.5 "$cbr stop"

#Call the finish procedure after 5 seconds of simulation time
$nS at 5.0 "finish"

#Run the simulation
$nS run


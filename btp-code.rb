require 'PP'

# initializing global variables
$initial_time = Time.now
$player_no
$player_end_config = {}
$node_no
$prv_ptm = {}
$graph = {}
$final_node_history = {}
$final_node_id
$history_list = []
$player_list = []
$global_id = 1
$final_objects = []
$objects_list = []

#-- done initializing global variables

def generate_prev_ptm_hash
  for i in 1..$player_no
    if i > 1
      $prv_ptm["p"+ i.to_s] = "p" + (i - 1).to_s
    else
      $prv_ptm["p"+ i.to_s] = "p" + $player_no.to_s
    end
  end
end

def find_and_print_next id
  obj = $objects_list.select {|u| u.uniq_id == id }
  
  puts "id = #{obj.first.uniq_id} , #{obj.first.history}, #{obj.first.id}, #{obj.first.position} --> " unless obj.first.nil?
  find_and_print_next obj.first.prev_id unless obj.first.nil?
end

def print_successful_routes

  $final_objects.each do |obj|
     
    puts "id = #{obj.uniq_id} , #{obj.history}, #{obj.id}, #{obj.position} --> "
    find_and_print_next(obj.prev_id)
  end
end

def generate_graph(node_no)
  z = []
  for i in 1..node_no
    puts "Enter the number of adjacent nodes for node number #{i} :"   
    no_of_adjacent_nodes = Integer(gets)
    for j in 1..no_of_adjacent_nodes
      puts "Enter the #{j}th adjacent node for node #{i}"
      z << Integer(gets)
    end
    $graph[i] = z
  end
  puts PP.pp($graph,"")
end

def generate_end_configurations
  posi = [1,2,3,4,5,6].permutation(3).reject{|u|  u[0]== 1 || u[0] == 5 || u[0] == 6 }
  #$player_list.each do |player|
  player = "p2"

    z = []
    
    array = [0,1].repeated_permutation($player_no).reject{|u| u == [0,0,0]}
    arrays = array.repeated_permutation($player_no).reject{|u| u[1][1] != 1 || u[2][2] != 1 || u[0] != [1,1,1] || u[1] == [1,1,1] || u[2] == [1,1,1] } #TODO Generic    
     
    arrays.each do |arr|
      hist_hash = Hash.new
      for i in 1..$player_no      
        hist_hash["p" + i.to_s] = arr[i - 1]        
      end
      
      hash1 = {}
      hash1["pos"] = []
      
        hash1["hist"] = hist_hash
      posi.each do |p|
        hash1["pos"] << p
        z << hash1 
      end
        
      
       
    end
    $player_end_config[player] = z
  #end      
end

def find_prev_node(node)
  
  adjacent_nodes =[]
  valid_nodes = []
  not_visited_nodes = []
  winner_history = []
  winner_position = []
  initial_nodes = []
  prev_ptm = $prv_ptm[node.ptm]
  
  node.history[prev_ptm].each_with_index do |n,c|
    not_visited_nodes << c + 1  if n == 0
  end
  occupied_nodes = []
  node.position.values.each do |a|
    occupied_nodes << a
  end
  for i in 1..$player_no
    winner_history << 1
    winner_position << i
  end
  
  adjacent_nodes = $graph[node.position[prev_ptm]]
  
  valid_nodes = adjacent_nodes - occupied_nodes - not_visited_nodes 
  
  puts " valid-nodes = #{valid_nodes.join(" ")} , adjacent-nodes = #{adjacent_nodes.join(" ")}, node-positions = #{node.position.values.join(" ")} 0-nodes = #{not_visited_nodes}"
  
   
  if(valid_nodes.length > 0)
    
    node.generate_id
    
    valid_nodes.each  do |v|
      
      new_node = Node.new()
      new_node = Marshal.load(Marshal.dump(node))
      new_node.position[prev_ptm] = v
      new_node.ptm = prev_ptm
      new_node.uniq_id = new_node.uniq_id + 1
      new_node.prev_id = node.uniq_id
      
      
            
      restricted_nodes = winner_position - [prev_ptm[1].to_i]
      
      if (restricted_nodes.include?(node.position[prev_ptm]) and node.history[prev_ptm] != winner_history) and [node.history[prev_ptm]] - [[0,0,1],[1,0,0],[0,1,0]] != 0  
        new_split_node = Node.new()
        new_split_node = Marshal.load(Marshal.dump(new_node))
        new_split_node.generate_id
        puts "Splitting Cases"
        new_split_node.uniq_id = new_split_node.uniq_id + 1
        new_split_node.history[prev_ptm][node.position[prev_ptm] - 1] = 0  
        find_prev_node(new_split_node)
        puts new_node.history
             
      end
      
      if restricted_nodes.include?(node.position[prev_ptm]) and node.history[prev_ptm] == winner_history  
        temphis = new_node.history
        temphis[prev_ptm][node.position[prev_ptm] - 1] = 0
        new_node.history = temphis
      end
      
      if new_node.id.join("") == $final_node_id && new_node.history == $final_node_history
        puts "routes exist"
        $final_objects << new_node
      else
        
        new_node_id = new_node.id.join("")
        
        unless $history_list.include?({"id" => new_node_id, "history" => new_node.history})
          $history_list << {"id" => new_node_id, "history" => new_node.history}
          $objects_list << new_node
          find_prev_node(new_node)
          puts "Searching next node #{new_node.id}"
        else
          puts "#{new_node.id} forms a loop"
        end
        
      end
    end
  else
    puts "no free nodes exist"
  end
end

def generate_player_list
  for i in 1..$player_no
    $player_list << "p" + i.to_s
  end
end  

def generate_final_id
  array = []
  for i in 1..$player_no
    array << i
    $final_node_history["p" + i.to_s] = Array.new($player_no){|j| j = 0}
  end
  array << 1
  $final_node_id = array.join("")
  $final_node_history.keys.each_with_index {|k,i| $final_node_history[k][i] = 1}  
end

class Node
  attr_accessor :history, :position, :ptm, :id, :player_no, :node_no, :prev_id, :next_id, :uniq_id
  
  
  def initialize
    @uniq_id = $global_id    
  end
  
  def generate_id
    
      @id = []
      $player_list.each do |p|
        @id << @position[p]
      end
      @id << @ptm[1].to_i  
        
  end
  
  
end

def input_data_and_initialize_globals
  puts "Enter the the number of players :"
  $player_no = Integer(gets)
  puts "Enter the number of nodes in the graph"
  $node_no = Integer(gets)
  generate_graph($node_no)
  generate_prev_ptm_hash

end

# -- Main function execution starts her


$player_no = 3
$node_no = 6
#generate_graph($node_no)
$graph = {1 =>[2,4,5,6],2=>[1,3,5],3=>[2,4,6],4=>[1,3,6],5=>[1,2,6],6=>[1,3,4,5] }
generate_final_id
generate_player_list
generate_prev_ptm_hash
generate_end_configurations



#a = Node.new
#a.history = {"p1" => [1,1,1], "p2" => [1,1,0],"p3" => [1,0,1]}
#a.position = {"p1" => 2,"p2" => 5, "p3" => 6}
#a.ptm = "p2"

#a.generate_id
#puts a.id.join("")


#find_prev_node(a)
#=begin
x = 1
v = $player_end_config["p2"]
  v.each do |a|
    $history_list = []
    node = Node.new
    node.history = a["hist"]
    node.position = {}
    a["pos"].each do|p|
    for i in 1.. $player_no
      node.position["p" + i.to_s] = p[i - 1]
      node.ptm = "p2"
      
      node.generate_id
      find_prev_node(node)
      puts "#{x} / #{v.length}"
      x = x + 1
    end
  end
    
     
    
end
#=end
print_successful_routes
puts "#{Time.now - $initial_time} Seconds"
#for items in $objects_list
#  puts "#{items.history}, #{items.uniq_id}"
#end
# -- Main function execetion stops here


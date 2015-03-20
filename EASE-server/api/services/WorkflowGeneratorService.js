

// Constructor
function Workflow(metaworkflow) {
  this.metaworkflowID = metaworkflow.id

  //console.log(metaworkflow.metatasks.length+"\n");
  this.tasks = []
  var tmp = [];
   // sails.models.metaworkflow.findOne({id:metaworkflow.id}).populate('metatasks').exec(
  // 	function(err,metaworkflow){
  // 		console.log(metaworkflow.metatasks.length)
  		
  // 		for (var i = 0; i < metaworkflow.metatasks.length; i++) {

		// var task = new Task(oldthis, metaworkflow.metatasks[i])

		// //console.log(task)
		// tmp.push(task)

  // };



  // 	})
  		console.log(metaworkflow.metatasks.length)
  		
  		for (var i = 0; i < metaworkflow.metatasks.length; i++) {

		var task = new Task(this, metaworkflow.metatasks[i])

		//console.log(task)
		this.tasks.push(task) }


}




function Task(workflow, metatask) {
	//this.workflow = workflow
	this.agentTypes = metatask.agentTypes
	this.agentAdaptations = [];
	this.metatask = metatask;
	console.log("n "+this.agentTypes+" \n");
}


Task.prototype.getSubtasks = function(cb) {

	var task = this;

	sails.models.agent.find({agentType: task.agentTypes}) //Finding all the agents which might be able to perform this task


    .exec(function (err, agents) { 

    	async.map(agents, function (agent, cb2)
    	{
    		var agentAdaptation = {agentID: agent.id}
    		agent.subTasksForTask(task.metatask, function(err, subtasks)
    		{
    			agentAdaptation.subtasks = subtasks;
    			cb2(err, agentAdaptation)
    		}

    		)

    	}, 

    	function (err, agentAdaptations) 
    	{
    		task.agentAdaptations = agentAdaptations;
    		console.log("Agent adaptations : " + JSON.stringify(agentAdaptations, null, 4));
    		cb(err) 

    	}

    	)

    })

}


function SubTask() {

}



module.exports = {

	workflow : Workflow,
	task: Task,


	generateWorkflows: function (metaworkflow, params) {

		sails.session.generatedWorkflows = sails.session.generatedWorkflows || []

		async.waterfall(
			[function (cb){
				workflow = new Workflow(metaworkflow);
				 cb (null,workflow);
			}
			,
			function (workflow,cb)
			{	
				console.log(workflow);
// until here, task undefined
				async.each(workflow.tasks, 

					function (task, cb2)
					{	
						console.log(task);
						task.getSubtasks(function (err) {cb2(err)})
					}, 

					function (err)
					{
						cb(err)
					}

				)
			}



			], 

			function (err) {
					
					console.log('Workflow : \n ' + JSON.stringify(workflow, null, 4))

					var agentAdaptations = [];

					for (var i = 0; i < workflow.tasks.length; i++)
					{
						var task = workflow.tasks[i];
						console.log('Task : \n' + JSON.stringify(task, null, 4));
						agentAdaptations.push(task.agentAdaptations);
					}

					workflow.paths = paths = MathService.cartesianProduct(agentAdaptations);
					console.log('Cartesian : \n' + JSON.stringify(workflow.paths, null, 4))

				

				} 

		)

	


	}
}

















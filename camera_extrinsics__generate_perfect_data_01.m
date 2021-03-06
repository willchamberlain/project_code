function camera_extrinsics__generate_perfect_data()


CentralCamera
%   classdef CentralCamera < Camera
%
%   The camera coordinate system is:
%
%       0------------> u X
%       |
%       |
%       |   + (principal point)
%       |
%       |   Z-axis is into the page.
%       v Y
CentralCamera

%-- default camera : need this to get the camera_K at zero offset
camera = CentralCamera('default');
move_trans_x = [ 0 0 0]';
camera = camera.move(  [   [ eye(3), move_trans_x ] ; [ 0 0 0 1 ]   ]  );  % :-- move in world coordinate system ( FLU ) : camera is aligned to 
[ camera_K , Focal_length , Principal_point ] = camera_extrinsics__camera_intrinsics_from_pctoolkit_camera(camera);


%----  Make some random 3D points : note they're separate by minimum 0.1m  ----%
num_datapoints = 20;  %  5mx3mx1.2m  
points_3D_random = [    (randperm(51, num_datapoints)-1)/10  ;   (randi(31, [1,num_datapoints])-1)./10  ;  5+(randi(13, [1,num_datapoints])-1)/10  ;    ]    

%-- 
cam_check = camera.move(  [   [ eye(3), [0 0 -5]' ] ; [ 0 0 0 1 ]   ]  );
points_2D = cam_check.project(points_3D_random);
figure('Name','points_2D <-- points_3D_random '); hold on; grid on; axis equal; xlabel('x'); ylabel('y'); zlabel('z');
plot([0 , 0 , 1024, 1024 , 0], [0 , 1024, 1024 , 0 , 0])            %  draw the image boundaries
plot2_rows(points_2D, 'rx')
figure('Name','points_3D_random '); hold on; grid on; axis equal; xlabel('x'); ylabel('y'); zlabel('z');
plot3_rows(points_3D_random , 'rx')
draw_axes_direct(cam_check.get_pose_rotation, cam_check.get_pose_translation, '', 0.5 )   % draw the camera pose

cam_check_2 = camera_extrinsics__place_camera();
points_2D = cam_check_2.project(points_3D_random);
figure('Name','points_2D <-- points_3D_random '); hold on; grid on; axis equal; xlabel('x'); ylabel('y'); zlabel('z');
plot([0 , 0 , 1024, 1024 , 0], [0 , 1024, 1024 , 0 , 0])            %  draw the image boundaries
plot2_rows(points_2D, 'rx')
figure('Name','points_3D_random '); hold on; grid on; axis equal; xlabel('x'); ylabel('y'); zlabel('z');
plot3_rows(points_3D_random , 'rx')
draw_axes_direct(cam_check_2.get_pose_rotation, cam_check_2.get_pose_translation, '', 0.5 )   % draw the camera pose

cam_check_2.ray
%--
figure('Name','points_3D_random '); hold on; grid on; axis equal;
plot3_rows(points_3D_random , 'rx')
draw_axes_direct(camera.get_pose_rotation, camera.get_pose_translation, '', 0.5 )   % draw the camera pose

figure('Name','points_2D <-- points_3D_random '); hold on; grid on; axis equal;
plot([0 , 0 , 1024, 1024 , 0], [0 , 1024, 1024 , 0 , 0])            %  draw the image boundaries
plot2_rows(points_2D, 'rx')

[R,T,Xc,best_solution, solution_set, Alph]=efficient_pnp_will( points_3D_random' , points_2D' , camera_K );      
extrinsic_estimate_as_local_to_world =  vertcat(  horzcat( R', (-(R')) * T )  ,   [ 0 0 0 1]  );          
max(max(abs(extrinsic_estimate_as_local_to_world - camera.get_pose_transform)))  < 1e-6

%--
% T_FLU_to_RDF(1:3,1:3)'*R
% extrinsic_estimate_as_local_to_world = [ [ R*T_FLU_to_RDF(1:3,1:3) , extrinsic_estimate_as_local_to_world(1:3,4)] ; [ 0 0 0 1 ]  ] 
% extrinsic_estimate_as_local_to_world - camera.get_pose_transform
% max(max(abs(extrinsic_estimate_as_local_to_world - camera.get_pose_transform))) 
% max(max(abs(extrinsic_estimate_as_local_to_world - camera.get_pose_transform)))  < 1e-6

%----  Now with subsets of over 15 iterations ----%
%{
    --- Lessons learnt ---
    - 2 repeated points give bad results
    - check that the sampled data is distinct:  datasample( dataset , subset_size , dataset_dim , 'Replace' , false )
%}
%%
%  OLD 
model_size = 4;
num_RANSAC_iterations = 15;   % otten 100-1000, but papers imply can be significantly less 
models = zeros(model_size,num_RANSAC_iterations, 'uint32');
models_max_diff_SE3_element = zeros(1,num_RANSAC_iterations);
models_pose = zeros(4,4,num_RANSAC_iterations);
for ii_=1:num_RANSAC_iterations 
    [ points_3D_model , model_datapoint_indices ] = datasample(points_3D_random, 4, 2, 'Replace', false);
    points_2D_model = points_2D(:,[model_datapoint_indices]);
    if camera_extrinsics__is_sample_degenerate( points_3D_model , points_2D_model ) 
        continue
    end
    models(:,ii_) = model_datapoint_indices;
    [R,T,Xc,best_solution, solution_set, Alph]=efficient_pnp_will( points_3D_model' , points_2D_model' , camera_K );     
    extrinsic_estimate_as_local_to_world =  vertcat(  horzcat( R', (-(R')) * T )  ,   [ 0 0 0 1]  );    
    models_pose(:,:,ii_) = extrinsic_estimate_as_local_to_world;
    models_max_diff_SE3_element(ii_) = max(max(abs(extrinsic_estimate_as_local_to_world - camera.get_pose_transform)));
end
for ii_=1:num_RANSAC_iterations 
    draw_axes_direct( models_pose(1:3,1:3,ii_) , models_pose(1:3,4,ii_) , '', 0.5 )   % draw the camera pose
end
figure;plot(models_max_diff_SE3_element );
% some good fits, some bad, even with perfect data

%%
% start : Error cause analysis for model size 4 with perfect data
    % would like to intuit any patterns: draw links between a pose estimate and the model datapoints
    for kk_ = find( models_max_diff_SE3_element > 0.1 )
        kk_
        for jj_ = 1:model_size
            plot3_rows(   [ models_pose(1:3,4,kk_)  , points_3D_random(:,models(jj_,kk_))  ]   ,  'g' )
        end
    end
% end : Error cause analysis for model size 4 with perfect data
    
%%
% try with a larger model, same dataset 
% --> 5 is better, 6 is much better : maybe due to dispersion --> could_ try that in 2D most easily , but inlier/consensus set size and/or mean reprojection
% error of inliers should sort it out
%    NOTE: show that the sum of all reprojection errors in the dataset is equivalent to the mean reprojection of the inliers 
%       BECAUSE the outliers conhtribute the same (under Tukey) so do not affect the mean/sum of inliers  
% OLD
camera = CentralCamera('default');
camera = camera.move(  [   [ eye(3), move_trans_x ] ; [ 0 0 0 1 ]   ]  );  % :-- move in world coordinate system ( FLU ) : camera is aligned to 

[ camera_K , Focal_length , Principal_point ] = camera_extrinsics__camera_intrinsics_from_pctoolkit_camera(camera) 

for model_size = 4:8
    num_RANSAC_iterations = 10;   % otten 100-1000, but papers imply can be significantly less 
    models = zeros(model_size,num_RANSAC_iterations, 'uint32');
    models_max_diff_SE3_element = zeros(1,num_RANSAC_iterations);
    models_pose = zeros(4,4,num_RANSAC_iterations);
    fig_3d_handle = figure('Name',sprintf( 'points_3D_random - model size %d' ,model_size) ); hold on; grid on; axis equal;
    plot3_rows(points_3D_random , 'rx')
    draw_axes_direct(camera.get_pose_rotation, camera.get_pose_translation, '', 0.5 )   % draw the camera pose
    for ii_=1:num_RANSAC_iterations 
        [ points_3D_model , model_datapoint_indices ] = datasample(points_3D_random, model_size, 2, 'Replace', false);
        points_2D_model = points_2D(:,[model_datapoint_indices]);
        if camera_extrinsics__is_sample_degenerate( points_3D_model , points_2D_model ) 
            continue
        end
        models(:,ii_) = model_datapoint_indices;
        [R,T,Xc,best_solution, solution_set, Alph]=efficient_pnp_will( points_3D_model' , points_2D_model' , camera_K );     
        extrinsic_estimate_as_local_to_world =  vertcat(  horzcat( R', (-(R')) * T )  ,   [ 0 0 0 1]  );    
        models_pose(:,:,ii_) = extrinsic_estimate_as_local_to_world;
        models_max_diff_SE3_element(ii_) = max(max(abs(extrinsic_estimate_as_local_to_world - camera.get_pose_transform)));
    end
    for ii_=1:num_RANSAC_iterations 
        figure(fig_3d_handle)
        draw_axes_direct( models_pose(1:3,1:3,ii_) , models_pose(1:3,4,ii_) , '', 0.5 )   % draw the camera pose        
    end
    figure('Name',sprintf('model errors-ish - model size %d',model_size)) ;plot(models_max_diff_SE3_element );
    drawnow
end

%% start: repeat the above, using   camera_extrinsics__iterate_epnp.m
% 2018_04_08
% OLD
num_cam_poses = 3;
model_size = 0;
model_size_range=[4,8];
model_size_range=[8,15];
num_RANSAC_iterations = 10;   % otten 100-1000, but papers imply can be significantly less 
models = zeros(model_size,num_RANSAC_iterations, 'uint32');
models_max_diff_SE3_element = zeros(1,num_RANSAC_iterations);
models_pose = zeros(4,4,num_RANSAC_iterations);

cameras = [];
for jj_ = 1:num_cam_poses
   camera =  camera_extrinsics__place_camera_safely(5, points_3D_random, 0.25);
%     while true
%         camera = camera_extrinsics__place_camera(5);
%         points_2D = camera.project(points_3D_random);
%         if sum( points_2D(1,:)>camera.limits(2) | ...
%         points_2D(2,:)>camera.limits(4) | ...
%         points_2D(1,:)<camera.limits(1) | ...
%         points_2D(2,:)<camera.limits(3) ) < size(points_3D_random/0.25)
%             display('break-ing');
%             break
%         else
%             display ('retry');
%         end 
%     end
    [ camera_K , Focal_length , Principal_point ] = camera_extrinsics__camera_intrinsics_from_pctoolkit_camera(camera) ;
    cameras = [ cameras ; camera ];
    
    for model_size = [8 11 14] %model_size_range(1):model_size_range(2)
           points_2D_preconditioned = points_2D;
           points_3D_random_preconditioned = points_3D_random;
           [ models , models_max_diff_SE3_element , models_extrinsic_estimate_as_local_to_world ] = ...  % , models_best_solution , models_solution_set ] = ...           
        camera_extrinsics__iterate_epnp  ( ...
            points_2D_preconditioned, points_3D_random_preconditioned, camera_K, ...
            num_RANSAC_iterations, model_size, ...
            camera.get_pose_transform);

        fig_2d_plot_errors_handle = figure('Name',sprintf('model errors-ish - model size %d',model_size)) ;plot(models_max_diff_SE3_element );

        fig_3d_handle = figure('Name',sprintf( 'points_3D_random - model size %d' ,model_size) ); hold on; grid on; axis equal;

        camera_extrinsics__plot_3d_point_3D_and_camera_pose(fig_3d_handle, points_3D_random,camera)    

        camera_extrinsics__plot_3d_estimated_poses   (fig_3d_handle, models_extrinsic_estimate_as_local_to_world)

        drawnow
    end    
end
% DONE 2018_04_08: repeat the above, using   camera_extrinsics__iterate_epnp.m
% end: repeat the above, using   camera_extrinsics__iterate_epnp.m    
%%   start: add reprojection error to determine inlier set 
%   see   /mnt/nixbig/ownCloud/project_code/iterate_sample_cam_605_pnp_reproject_2.m
% NOW
%----  Make some random 3D points : note they're separate by minimum 0.1m  ----%
num_datapoints = 20;  %  5mx3mx1.2m  
points_3D_random = [    (randperm(51, num_datapoints)-1)/10  ;   (randi(31, [1,num_datapoints])-1)./10  ;  5+(randi(13, [1,num_datapoints])-1)/10  ;    ]    
%---- 
%-- default camera : need this to get the camera_K at zero offset
camera_default = CentralCamera('default');
move_trans_x = [ 0 0 0]';
camera_default = camera_default.move(  [   [ eye(3), move_trans_x ] ; [ 0 0 0 1 ]   ]  );  % :-- move in world coordinate system ( FLU ) : camera is aligned to 
[ camera_K , Focal_length , Principal_point ] = camera_extrinsics__camera_intrinsics_from_pctoolkit_camera(camera_default);
%----
num_cam_poses = 3;
model_size = 0;
model_size_range=[4,8];
model_size_range=[8,9];
num_cam_poses = 3;
num_RANSAC_iterations = 10;   % otten 100-1000, but papers imply can be significantly less 
num_RANSAC_iterations = 3;
models = zeros(model_size,num_RANSAC_iterations, 'uint32');
models_max_diff_SE3_element = zeros(1,num_RANSAC_iterations);
models_pose = zeros(4,4,num_RANSAC_iterations);
cameras = [];
points_3D_random_hom = [ points_3D_random ; ones(1,size(points_3D_random,2)) ];
for jj_ = 1:num_cam_poses
    camera =  camera_extrinsics__place_camera_safely(10,30, points_3D_random, 0.8);
    %[ camera_K , Focal_length , Principal_point ] = camera_extrinsics__camera_intrinsics_from_pctoolkit_camera(camera);
    cameras = [ cameras ; camera ];
    
    points_2D = camera.project(points_3D_random);
    
    for model_size = [4 5 6]  %model_size_range(1):model_size_range(2)
           points_2D_preconditioned = points_2D;
           points_3D_random_preconditioned = points_3D_random;
           [ models , models_max_diff_SE3_element , models_extrinsic_estimate_as_local_to_world ] = ...  % , models_best_solution , models_solution_set ] = ...           
        camera_extrinsics__iterate_epnp  ( ...
            points_2D_preconditioned, points_3D_random_preconditioned, camera_K, ...
            num_RANSAC_iterations, model_size, ...
            camera.get_pose_transform);

        fig_2d_plot_errors_handle = figure('Name',sprintf('model errors-ish - model size %d',model_size)) ;plot(models_max_diff_SE3_element );

        fig_3d_handle = figure('Name',sprintf( 'points_3D_random - model size %d' ,model_size) ); hold on; grid on; axis equal; xlabel('x'); ylabel('y'); zlabel('z')

        camera_extrinsics__plot_3d_point_3D_and_camera_pose(fig_3d_handle, points_3D_random,camera)    

        camera_extrinsics__plot_3d_estimated_poses   (fig_3d_handle, models_extrinsic_estimate_as_local_to_world)

        drawnow
        
        display('now reproject');
        for ii_ = 1:size(models_extrinsic_estimate_as_local_to_world,3)   
            % now  project the 3D to 2D - PC style
            camera_estimated = CentralCamera('default');
            camera_estimated = camera_estimated.move(models_extrinsic_estimate_as_local_to_world(:,:,ii_));
            points_2D_estimated = camera_estimated.project(points_3D_random);
            reprojected_errs_uv( : , : , ii_  ) = points_2D_preconditioned - points_2D_estimated(1:2,:)  ;
            reprojected_errs_euc_sq = reprojected_errs_uv( 1 , : , ii_  ).^2 + reprojected_errs_uv( 2 , : , ii_  ).^2;
            models_reprojected_errs_euc_sq_total( ii_ ) = sum(reprojected_errs_euc_sq);
            figure('Name', ...
                sprintf( 'points_2D - model size %d, model %d, sum(err_sq)=%f' ,model_size, ii_,models_reprojected_errs_euc_sq_total(ii_))) ; 
                hold on;       plot2_rows(points_2D_preconditioned, 'rx') ;        plot2_rows(points_2D_estimated(1:2,:) , 'bs') ;

            
            %{
            % now  express the 3D points in the estimated camera model's frame
            extrinsic_estimate_as_local_to_world = models_extrinsic_estimate_as_local_to_world(:,:,ii_);
            models_extrinsic_estimate_as_world_to_local(:,:,ii_) =  ...
                vertcat(  horzcat( extrinsic_estimate_as_local_to_world(1:3,1:3)', extrinsic_estimate_as_local_to_world(1:3,1:3)' * extrinsic_estimate_as_local_to_world(1:3,4)*-1)  ,   [ 0 0 0 1]  );                
                %  pt_camera = world_to_local * pt_world;
            points_3D_in_estimated_camera_model = models_extrinsic_estimate_as_world_to_local(:,:,ii_) * points_3D_random_hom  ;
            points_3D_in_estimated_camera_model_RDF = flu_to_rdf( points_3D_in_estimated_camera_model );    
            % now  project the 3D to 2D
            camera_K_hom_RDF = [ camera_K , [ 0 0 0 ]'  ] ;
            reprojected_points_2D = camera_K_hom_RDF  *  points_3D_in_estimated_camera_model_RDF  ;
                % now  normalise the projected points
                reprojected__ = reprojected_points_2D ;
                reprojected__(1,:)= reprojected_points_2D(1,:).* reprojected_points_2D(3,:).^-1  ;
                reprojected__(2,:)= reprojected_points_2D(2,:).* reprojected_points_2D(3,:).^-1  ;
                reprojected__(3,:)= reprojected_points_2D(3,:).* reprojected_points_2D(3,:).^-1  ;
                % now undistort  -  LATER - see /mnt/nixbig/ownCloud/project_code/iterate_sample_cam_605_pnp_reproject_2.m
                % now diff
                reprojected_errs_uv( : , : , ii_  ) = abs(points_2D_preconditioned - reprojected__(1:2,:) )  ;
                reprojected_errs_euc_sq = reprojected_errs_uv( 1 , : , ii_  ).^2 + reprojected_errs_uv( 2 , : , ii_  ).^2;
                models_reprojected_errs_euc_sq_total( ii_ ) = sum(reprojected_errs_euc_sq);
                %}
        end
%         check that world-to-local is the inverse of local-to-world (camera_extrinsics)
%         for ii_ = 1:size(models_extrinsic_estimate_as_local_to_world,3)
%             models_extrinsic_estimate_as_local_to_world(:,:,ii_)*models_extrinsic_estimate_as_world_to_local(:,:,ii_)
%         end
%         for ii_ = 1:size(models_extrinsic_estimate_as_local_to_world,3)
%             models_extrinsic_estimate_as_world_to_local(:,:,ii_)*models_extrinsic_estimate_as_local_to_world(:,:,ii_)
%         end
%         figure; hold on;       plot2_rows(points_2D_preconditioned, 'bs') ;        plot2_rows(reprojected__(1:2,:) , 'rx') ;
        
        
        camera_K_hom_RDF = [ camera_K , [ 0 0 0 ]'  ] ;
    end    
end



%%

% Copy all of the above into a wrapper function which just runs it n times for model size m: :  one step toward RANSAC
% --> [ models , models_max_diff_SE3_element ] =  camera_extrinsics__iterate_epnp  ( points_2D, points_3D_random, num_RANSAC_iterations, model_size)
TODO_REPLACE_extrinsic_estimate_as_local_to_world = extrinsic_estimate_as_local_to_world ;
[ models , models_max_diff_SE3_element ] =  camera_extrinsics__iterate_epnp  ( points_2D, points_3D_random , camera_K, num_RANSAC_iterations, model_size  ,  TODO_REPLACE_extrinsic_estimate_as_local_to_world  )

camera_extrinsics__is_sample_degenerate( points_3D_model , points_2D_model )
camera_extrinsics__is_sample_degenerate( points_3D_model , [ points_2D_model';points_2D_model']' )
camera_extrinsics__is_sample_degenerate( [ points_3D_model' ; points_3D_model' ]'  ,  points_2D_model )
%--------------------------------------

%----  Now add some  noise to the 2D ----%

%----  Now add some  latency to the 3D ----%


end